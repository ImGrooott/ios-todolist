//

//  ContentView.swift

//  MySimpleTodo

//

//  Created by 김성현 on 11/24/25.

//

import SwiftUI

// Identifiable: 리스트에서 순서를 헷갈리지 않게 각 아이템에 명찰을 달아줌

// Codable: 구조체를 저장하려면 0,1로 분해해서 포장해야하는데 이걸 자동으로 해줌.

struct TodoItem: Identifiable, Codable, Hashable {
    var id = UUID()

    var title: String

    var isDone: Bool

    var subTasks: [SubTask]
}

struct SubTask: Identifiable, Codable, Hashable {
    var id = UUID()

    var title: String

    var isDone: Bool

    var memo: String
}

import Foundation

import Observation

@Observable // 이 매크로가 이 객체가 관찰 가능하다는것을 알려준다.

class TaskStore {
    var tasks: [TodoItem] = []

    func addTask(title: String) {
        let newTask = TodoItem(title: title, isDone: false, subTasks: [])

        tasks.append(newTask)

        saveTasks()
    }

    func removeTask(task: TodoItem) {
        if let index = tasks.firstIndex(of: task) {
            tasks.remove(at: index)
        }

        saveTasks()
    }

    // 데이터를 저장한다.

    func saveTasks() {
        if let encodedData = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedData, forKey: "SavedTasks")
        }

        print(tasks)
    }

    // 데이터를 불러와서 decoded한다.

    func loadTasks() {
        if let savedData = UserDefaults.standard.data(forKey: "SavedTasks") {
            if let decodedTasks = try? JSONDecoder().decode([TodoItem].self, from: savedData) {
                tasks = decodedTasks
            }
        }
    }
}

struct ContentView: View {
    // 데이터를 담을 변수 만들기

    @State private var newTask = "" // 입력창에 쓸 글자

    @State private var tasks: [TodoItem] = []

    @State private var taskStore = TaskStore()
    var body: some View {
        // 이 안에서는 다른 화면으로 이동할 수 있다.
        NavigationStack {
            // 2. 화면 배치 시작 (VStack: 위에서 아래로 쌓기
            VStack {
                Text("작업 목록")

                    .font(.largeTitle)
                    .padding()

                // 3. 입력창과 버튼을 가로로 배치

                HStack {
                    TextField("할 일을 입력하세요...", text: $newTask).textFieldStyle(RoundedBorderTextFieldStyle())

                    // 텍스트는 왼쪽, 버튼은 오른쪽으로 밀어주는 역할을 한다.

                    Spacer()

                    Button("추가") {
                        if !newTask.isEmpty {
                            taskStore.addTask(title: newTask)

                            newTask = ""
                        }
                    }
                }

                .padding()

                // 4. 리스트 보여주기

                List {
                    ForEach($taskStore.tasks) { $task in
                        HStack {
                            NavigationLink(task.title) {
                                DetailView(task: $task)
                            }

                            Spacer()

                            Button("삭제") {
                                taskStore.removeTask(task: task)
                            }
                        }
                    }
                }

                .onAppear {
                    taskStore.loadTasks()
                }
            }

        }.onChange(of: taskStore.tasks) {
            taskStore.saveTasks()
        }

        .padding()
    }
}

struct DetailView: View {
    @Binding var task: TodoItem // 목록에서 전달받을 할 일 내용

    @State private var newSubtaskTitle: String = ""

    var body: some View {
        VStack {
            Text(task.title)
                .font(.largeTitle)
                .foregroundColor(.gray)

            HStack {
                TextField("플로우", text: $newSubtaskTitle).padding()

                Button("세부 할일 추가") {
                    let newSubtask = SubTask(title: newSubtaskTitle, isDone: false, memo: "")

                    task.subTasks.append(newSubtask)

                    newSubtaskTitle = ""

                }.padding()
            }

            List {
                ForEach(task.subTasks) { subTask in
                    Text(subTask.title)
                }
            }

        }.frame(minWidth: 300, minHeight: 300) // 창 크기 넉넉하게
            .navigationTitle("세부할일 관리")
            .padding()
    }
}

#Preview {
    ContentView()
}
