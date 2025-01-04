//: [Previous](@previous)
/*:
 # TaskGroups
 
 You can use TaskGroups to add a dynamic number of `Task`s
 and then also within the closuse, handle the result
 
 the `of:` parameter
 */

Task.detached {
    await withTaskGroup(of: String.self) { taskGroup in
        
        for i in (0...10) {
            taskGroup.addTask {
                try? await Task.sleep(nanoseconds: .random(in: 1_000...3_000))
                return "Hello World " + String(i)
            }
        }
        
        for await result in taskGroup {
            result
        }
    }
}
/*:
Notice that in the first example, the `withTaskGroup` doesn't return anything, but you can make it return with an overload:
 */

Task.detached {
   let finalResult =  await withTaskGroup(of: String.self, returning: String.self) { taskGroup in
        
        for i in (0...10) {
            taskGroup.addTask {
                try? await Task.sleep(nanoseconds: .random(in: 1_000...3_000))
                return "Hello World " + String(i)
            }
        }
        
        var finalResult = ""
        for await result in taskGroup {
            finalResult += result
        }
        
        return finalResult
    }
    
    print(finalResult)
}

/*:
 Note there are also other things you can do with the TaskGroup, like await the first result only:

 */

Task.detached {
   let finalResult =  await withTaskGroup(of: String.self, returning: String.self) { taskGroup in
        
        for i in (0...10) {
            taskGroup.addTask {
                try? await Task.sleep(nanoseconds: .random(in: 1_000...3_000))
                return "Hello World " + String(i)
            }
        }
        
       return await taskGroup.next()
    }
    
    print(finalResult)
}


//: [Next](@next)
