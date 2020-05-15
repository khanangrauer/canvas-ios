//
// This file is part of Canvas.
// Copyright (C) 2018-present  Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import XCTest
@testable import Core

class APIDiscussionTests: XCTestCase {
    func testPostDiscussionTopicRequest() {
        let assignment = APIAssignmentParameters(
            name: "A",
            description: "d",
            points_possible: 10,
            due_at: Date(),
            submission_types: [SubmissionType.discussion_topic],
            allowed_extensions: [],
            published: true,
            grading_type: .percent,
            lock_at: nil,
            unlock_at: nil
        )
        let expectedBody = PostDiscussionTopicRequest.Body(title: "T", message: "M", published: true, assignment: assignment)
        let context = ContextModel(.course, id: "1")
        let request = PostDiscussionTopicRequest(context: context, body: expectedBody)

        XCTAssertEqual(request.path, "courses/1/discussion_topics")
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.body, expectedBody)
    }

    func testPostDiscussionEntryRequest() {
        let context = ContextModel(.course, id: "1")
        let url = Bundle(for: Self.self).url(forResource: "TestImage", withExtension: "png")!
        let request = PostDiscussionEntryRequest(context: context, topicID: "42", message: "Hello There", attachment: url)

        XCTAssertEqual(request.path, "courses/1/discussion_topics/42/entries")
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.form?.count, 2)
        XCTAssertEqual(request.form?.first?.key, "message")
        XCTAssertEqual(request.form?.first?.value, .string("Hello There"))
        XCTAssertEqual(request.form?.last?.key, "attachment")
        XCTAssertEqual(request.form?.last?.value, .file(
            filename: url.lastPathComponent,
            type: "application/octet-stream",
            at: url
        ))

        let reply = PostDiscussionEntryRequest(context: context, topicID: "42", entryID: "1", message: "Reply")
        XCTAssertEqual(reply.path, "courses/1/discussion_topics/42/entries/1/replies")
    }
}

class ListDiscussionEntriesRequestTests: XCTestCase {
    func testPath() {
        let request = ListDiscussionEntriesRequest(context: ContextModel(.course, id: "1"), topicID: "2")
        XCTAssertEqual(request.path, "courses/1/discussion_topics/2/entries")
    }
}

class GetDiscussionTopicRequestTests: XCTestCase {
    func testPath() {
        let request = GetDiscussionTopicRequest(context: ContextModel(.course, id: "1"), topicID: "2")
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.path, "courses/1/discussion_topics/2")
    }

    func testQuery() {
        let request = GetDiscussionTopicRequest(context: ContextModel(.course, id: "1"), topicID: "2", include: [.allDates, .overrides, .sections, .sectionsUserCount])
        XCTAssertEqual(request.query, [
            .include(["all_dates", "overrides", "sections", "section_user_count"]),
        ])
    }
}

class GetDiscussionViewRequestTests: XCTestCase {
    func testPath() {
        let request = GetDiscussionViewRequest(context: ContextModel(.course, id: "1"), topicID: "2")
        XCTAssertEqual(request.path, "courses/1/discussion_topics/2/view")
    }

    func testQuery() {
        let request = GetDiscussionViewRequest(context: ContextModel(.course, id: "1"), topicID: "2", includeNewEntries: true)
        XCTAssertEqual(request.queryItems, [URLQueryItem(name: "include_new_entries", value: "1")])
    }
}

class ListDiscussionTopicsRequestTests: XCTestCase {
    func testPath() {
        let request = ListDiscussionTopicsRequest(context: ContextModel(.course, id: "1"))
        XCTAssertEqual(request.path, "courses/1/discussion_topics")
    }

    func testQuery() {
        let request = ListDiscussionTopicsRequest(context: ContextModel(.course, id: "1"), perPage: 25, include: [.allDates, .overrides, .sections, .sectionsUserCount])
        XCTAssertEqual(request.queryItems, [
            URLQueryItem(name: "per_page", value: "25"),
            URLQueryItem(name: "include[]", value: "all_dates"),
            URLQueryItem(name: "include[]", value: "overrides"),
            URLQueryItem(name: "include[]", value: "sections"),
            URLQueryItem(name: "include[]", value: "section_user_count"),
        ])
    }
}
