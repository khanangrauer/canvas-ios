// @flow

import React, { Component } from 'react'
import {
  View,
  FlatList,
  StyleSheet,
  NetInfo,
  AlertIOS,
} from 'react-native'
import { connect } from 'react-redux'
import type {
  SubmissionListProps,
  SubmissionProps,
  SubmissionDataProps,
} from './submission-prop-types'
import find from 'lodash/find'
import { mapStateToProps } from './map-state-to-props'
import i18n from 'format-message'
import SubmissionRow from './SubmissionRow'
import SubmissionActions from './actions'
import EnrollmentActions from '../../enrollments/actions'
import refresh from '../../../utils/refresh'
import Screen from '../../../routing/Screen'
import Navigator from '../../../routing/Navigator'
import SubmissionsHeader, { type SubmissionFilterOption, type SelectedSubmissionFilter } from '../SubmissionsHeader'
import Images from '../../../images'

type Props = SubmissionListProps & { navigator: Navigator } & RefreshProps
type State = {
  submissions: Array<SubmissionDataProps>,
  isConnected: boolean,
}

export class SubmissionList extends Component {
  props: Props
  state: State

  filterOptions: SubmissionFilterOption[]
  selectedFilter: ?SelectedSubmissionFilter

  constructor (props: Props) {
    super(props)

    this.state = {
      submissions: props.submissions || [],
      isConnected: true,
    }

    this.filterOptions = SubmissionsHeader.defaultFilterOptions()
  }

  componentWillMount = () => {
    const type = this.props.filterType
    if (type) {
      const filter = find(this.filterOptions, { type })
      if (filter) {
        this.selectedFilter = { filter }
      }
      this.updateSubmissions(this.props.submissions)
    }
    NetInfo.isConnected.fetch().then(this.setConnection)
    NetInfo.isConnected.addEventListener('change', this.setConnection)
  }

  componentWillUnmount = () => {
    NetInfo.isConnected.removeEventListener('change', this.setConnection)
  }

  componentWillReceiveProps = (newProps: Props) => {
    this.updateSubmissions(newProps.submissions)
  }

  setConnection = (isConnected: boolean) => {
    this.setState({ isConnected })
  }

  keyExtractor = (item: SubmissionProps) => {
    return item.userID
  }

  navigateToSubmission = (userID: string) => {
    if (!global.V04) { return } // such features
    if (!this.state.isConnected) {
      return AlertIOS.alert(i18n('No internet connection'), i18n('This action requires an internet connection.'))
    }

    const path = `/courses/${this.props.courseID}/assignments/${this.props.assignmentID}/submissions/${userID}`
    this.props.navigator.show(
      path,
      { modal: true },
      { selectedFilter: this.selectedFilter }
    )
  }

  renderRow = ({ item }: { item: SubmissionProps }) => {
    return <SubmissionRow {...item} onPress={this.navigateToSubmission} anonymous={this.props.anonymous} />
  }

  updateFilter = (filter: SelectedSubmissionFilter) => {
    this.selectedFilter = filter
    this.updateSubmissions(this.props.submissions)
  }

  clearFilter = () => {
    this.selectedFilter = null
    this.updateSubmissions(this.props.submissions)
  }

  updateSubmissions = (submissions: SubmissionDataProps[]) => {
    const selected = this.selectedFilter
    let filtered = submissions
    if (selected && selected.filter && selected.filter.filterFunc) {
      filtered = selected.filter.filterFunc(submissions, selected.metadata)
    }

    this.setState({
      submissions: filtered,
    })
  }

  openSettings = () => {
    this.props.navigator.show(`/courses/${this.props.courseID}/assignments/${this.props.assignmentID}/submission_settings`, {
      modal: true,
      modalPresentationStyle: 'fullscreen',
    })
  }

  render () {
    return (
      <Screen
        title={i18n('Submissions')}
        navBarColor={this.props.courseColor}
        navBarStyle='dark'
        rightBarButtons={[{
          accessibilityLabel: i18n('Submission Settings'),
          image: Images.course.settings,
          testID: 'submission-list.settings',
          action: this.openSettings,
        }]}
      >
        <View style={styles.container}>
          <SubmissionsHeader
            filterOptions={this.filterOptions}
            selectedFilter={this.selectedFilter}
            onClearFilter={this.clearFilter}
            onSelectFilter={this.updateFilter}
            pointsPossible={this.props.pointsPossible} />
          { /* $FlowFixMe I seriously have no idea why this is complaining about flatlist not having some properties */ }
          <FlatList
            data={this.state.submissions}
            keyExtractor={this.keyExtractor}
            testID='submission-list'
            renderItem={this.renderRow}
            refreshing={this.props.pending}
            onRefresh={this.props.refresh}
            />
        </View>
      </Screen>
    )
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    marginBottom: global.tabBarHeight,

  },
  header: {
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'lightgrey',
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    paddingTop: 16,
    paddingBottom: 12,
    paddingHorizontal: 16,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#2d3b44',
  },
  filterButton: {
    marginBottom: 1,
  },
})

export function refreshSubmissionList (props: SubmissionListProps): void {
  props.refreshSubmissions(props.courseID, props.assignmentID)
  props.refreshEnrollments(props.courseID)
}

export function shouldRefresh (props: SubmissionListProps): boolean {
  return props.shouldRefresh
}

const Refreshed = refresh(
  refreshSubmissionList,
  shouldRefresh,
  props => props.pending
)(SubmissionList)
const Connected = connect(mapStateToProps, { ...SubmissionActions, ...EnrollmentActions })(Refreshed)
export default (Connected: Component<any, SubmissionListProps, any>)
