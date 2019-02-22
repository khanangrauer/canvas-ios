//
// Copyright (C) 2016-present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import ReactiveSwift
import Result

open class Dispatcher<Input, Output, E: Error> {
	fileprivate let executeClosure: (Input) -> SignalProducer<Output, E>
	fileprivate let eventsObserver: Signal<Event<Output, E>, NoError>.Observer

	/// A signal of all events generated from applications of the Dispatcher.
	///
	/// In other words, this will send every `Event` from every signal generated
	/// by each SignalProducer returned from apply().
    public let events: Signal<Event<Output, E>, NoError>

	/// A signal of all values generated from applications of the Dispatcher.
	///
	/// In other words, this will send every value from every signal generated
	/// by each SignalProducer returned from apply().
    public let values: Signal<Output, NoError>

	/// A signal of all errors generated from applications of the Dispatcher.
	///
	/// In other words, this will send errors from every signal generated by
	/// each SignalProducer returned from apply().
    public let errors: Signal<E, NoError>

	public init(execute: @escaping (Input) -> SignalProducer<Output, E>) {
        executeClosure = execute
		(events, eventsObserver) = Signal<Event<Output, E>, NoError>.pipe()

		values = events.map { $0.value }.skipNil()
		errors = events.map { $0.error }.skipNil()
    }

	/// Creates a SignalProducer that, when started, will dispatch the input
	/// then forward the results upon the produced Signal.
	///
	/// - parameters:
	///   - input: A value that will be passed to the closure creating the signal
	///            producer.
	
	open func apply(_ input: Input) -> SignalProducer<Output, E> {
		return SignalProducer { observer, disposable in
			self.executeClosure(input).startWithSignal { signal, signalDisposable in
				disposable.add(signalDisposable)

				signal.observe { event in
					observer.action(event)
                    self.eventsObserver.send(value: event)
				}
			}
		}
    }
}
