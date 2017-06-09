/**
 * @flow
 */

import React, { Component } from 'react'
import color from '../../common/colors'
import * as Progress from 'react-native-progress'
import { Text, MEDIUM_FONT } from '../../common/text'
import {
  View,
  StyleSheet,
} from 'react-native'

export type SubmissionGraphProps = {
  total: number,
  current: number,
  label: string,
}

export default class SubmissionGraph extends Component<any, SubmissionGraphProps, any> {
  render () {
    let { current, label, total } = this.props
    let formattedData = current
    if (!current) {
      current = 0.0001
      formattedData = 0
    }

    return (
      <View style={submissionsGraphStyle.container}>
        <View style={submissionsGraphStyle.circleContainer}>
          <Progress.Circle size={submissionCircles.size}
                           thickness={submissionCircles.thickness}
                           progress={ current / total }
                           borderWidth={0}
                           unfilledColor={submissionCircles.backgroundColor}
                           color={submissionCircles.tint}
                           showsText={true}
                           textStyle={submissionsGraphStyle.innerText}
                           formatText={progress => `${formattedData}`} />
        </View>
        <Text style={submissionsGraphStyle.label}>{label}</Text>
      </View>
    )
  }
}

const submissionCircles: { [key: string]: any } = {
  size: 70,
  thickness: 7,
  tint: '#00e0ff',
  backgroundColor: '#F5F5F5',
}

const submissionsGraphStyle = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
  },
  label: {
    flex: 1,
    textAlign: 'center',
    fontSize: 12,
    marginTop: 8,
    fontWeight: '500',
  },
  circleContainer: {
    flex: 1,
  },
  innerText: {
    color: color.darkText,
    fontFamily: MEDIUM_FONT,
    fontSize: 16,
  },
})
