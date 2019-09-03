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

import CoreData
import Foundation

public class GetAssignments: CollectionUseCase {
    public enum Sort: String {
        case position, dueAt, name
    }

    public typealias Model = Assignment
    public let courseID: String
    private let sort: Sort

    public init(courseID: String, sort: Sort = .position) {
        self.courseID = courseID
        self.sort = sort
    }

    public var cacheKey: String? {
        return "get-\(courseID)-assignments"
    }

    public var request: GetAssignmentsRequest {
        let orderBy: GetAssignmentsRequest.OrderBy
        switch sort {
        case .position, .dueAt:
            orderBy = .position
        case .name:
            orderBy = .name
        }
        return GetAssignmentsRequest(courseID: courseID, orderBy: orderBy)
    }

    public var scope: Scope {
        switch sort {
        case .dueAt:
            //  this puts nil dueAt at the bottom of the list
            let a = NSSortDescriptor(key: #keyPath(Assignment.dueAtOrder), ascending: true)
            let b = NSSortDescriptor(key: #keyPath(Assignment.dueAt), ascending: true)
            let c = NSSortDescriptor(key: #keyPath(Assignment.name), ascending: true, selector: #selector(NSString.localizedStandardCompare))
            let predicate = NSPredicate(format: "%K == %@", argumentArray: [#keyPath(Assignment.courseID), courseID])
            return Scope(predicate: predicate, order: [a, b, c])
        case .position:
            return .where(#keyPath(Assignment.courseID), equals: courseID, orderBy: #keyPath(Assignment.position))
        case .name:
            return .where(#keyPath(Assignment.courseID), equals: courseID, orderBy: #keyPath(Assignment.name))
        }
    }

    public func write(response: [APIAssignment]?, urlResponse: URLResponse?, to client: NSManagedObjectContext) {
        guard let response = response else {
            return
        }

        for item in response {
            let predicate = NSPredicate(format: "%K == %@", #keyPath(Assignment.id), item.id.value)
            let model: Assignment = client.fetch(predicate).first ?? client.insert()
            model.update(fromApiModel: item, in: client, updateSubmission: false)
        }
    }
}

public class GetSubmittableAssignments: GetAssignments {
    public init(courseID: String) {
        super.init(courseID: courseID, sort: .name)
    }

    public override var scope: Scope {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", #keyPath(Assignment.courseID), courseID),
            NSPredicate(format: "%K == FALSE", #keyPath(Assignment.lockedForUser)),
            NSPredicate(format: "%K == NIL OR %K > %@", #keyPath(Assignment.lockAt), #keyPath(Assignment.lockAt), NSDate()),
            NSPredicate(format: "%K == NIL OR %K <= %@", #keyPath(Assignment.unlockAt), #keyPath(Assignment.unlockAt), NSDate()),
        ])
        return Scope(predicate: predicate, orderBy: #keyPath(Assignment.name))
    }
}
