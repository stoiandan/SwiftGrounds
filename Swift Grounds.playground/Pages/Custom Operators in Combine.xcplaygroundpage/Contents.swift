/*:
 
 # Welcom to “Custom Operators in Combine”
 
 In this tutorial, we are going to see how combine “operators” (i.e. publishers having an upstream publisher and a downstream subscriber to which they receive/send data) are build.
 */
import Combine
/*:
 We will start with a simple Just publisher, holding a value:
 */
Just(5)
/*:
  Our desire is to simply be able to call a function `double()` on Just that will double our value:
 
 `Just(5).double() // 2`
 
 To ilustrate a simple version of what we want to acheive, we can use the build-in `map()` operator.
 
 Then all we need to do is to add an extension method to every publisher that outputs an Integer and map the value to it's coresponding double:
 */
extension Publisher where Output == Int {
    func easyDouble() -> some Publisher {
        let mapPublisher = Publishers.Map(upstream: self, transform: { $0 * 2 })
        Swift.print("Easy double called now!")
        return mapPublisher
    }
}

/*:
 And we use it as such (also we need to store the subscription)
 */
var cancellable: [AnyCancellable] = []

Just(7).easyDouble().sink(receiveCompletion: {_ in }, receiveValue: { val in print("We got \(val)" )})
    .store(in: &cancellable)



/*:
  We're creating a new publisher, generic over some Upstream type,
   who's also a publisher and publishes an Integer
 */

extension Publishers {
    struct Double<Upstream : Publisher>: Publisher
    where Upstream.Output == Int {
        
        /*:
         We make sure our generic Double publisher always matches the output and failure
         type of it's Upstream
         */
        typealias Output = Upstream.Output
        
        typealias Failure = Upstream.Failure
        
        // store upstream
        let upstream: Upstream
        
        /*
         Most important, when downstream subscribes to us, we immediately wrapp our initial
         subcriber into our own, custom-built `DoubleSubscriber` that will act as a proxy.
         Forwarading everyting from upstream, except with a double value
         So, once we receive a subscriber from downstream, we subscribe ourselves to upstream
         */
        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            let subscriber = DoubleSubscriber(subscriber)
            upstream.receive(subscriber: subscriber)
        }
        
        init(upstream: Upstream) {
            self.upstream = upstream
        }
    }
}


/*:
  The DobuleSubscriber is also generic, this time not upon an Upstream publisher,
  but on a Downstream subscriber to which we proxy values.
 */
extension Publishers.Double {
    class DoubleSubscriber<Downstream : Subscriber>: Subscriber
    /*
     Because `DoubleSubscriber` lives inside (as an extension of `Publishers.Double`) we can
     make use of it's generic Output and Failure types; here is where a powerful expression of associated types and  protocol oriented programming
     */
    where Downstream.Input == Output, Downstream.Failure == Failure {
        
        
        func receive(_ input: Publishers.Double<Upstream>.Output) -> Subscribers.Demand {
            /*:
             Whenever we receive a value from upstream, we send it's double to downstream,
             get the new demand from downstream, and proxy it back to upstream
             */
            let newDemand = subscriber.receive(input * 2)
            return newDemand
        }
        
        /*:
         simply forward the completion
         */
        func receive(completion:
            Subscribers.Completion<Publishers.Double<Upstream>.Failure>) {
            subscriber.receive(completion: completion)
        }
        
        typealias Input = Publishers.Double<Upstream>.Output
        
        typealias Failure = Publishers.Double<Upstream>.Failure
        
        /*:
         simply forward the subscription
         */
        func receive(subscription: any Subscription) {
            subscriber.receive(subscription: subscription)
        }
        
        private let subscriber: Downstream
        
        init(_ subscriber: Downstream) {
            self.subscriber = subscriber
        }
        
    }
}

/*:
 Finally we can just make an extension method for every type that impelements the
 Publisher protocol so that it has access to our new operator.
 In this extension Method all we do is to create a DoublePublisher and bind it to the
 publisher who uses the extension method; which we will access via `self`:
 */
extension Publisher
where Output == Int{
    public func double() -> some Publisher {
        let doublePublisher = Publishers.Double(upstream: self)
        Swift.print("From the custom build publisher")
        return doublePublisher
    }
}

/*:
 Since in our extension method we return back a new publisher and an opaque type (`some Publisher`) we can subscribe to our publisher with `sink` or any other subcriber and the chain is formed:
 */

Just(5).double().sink(receiveCompletion: {_ in }, receiveValue: { val in print("We got \(val)" )})
    .store(in: &cancellable)
