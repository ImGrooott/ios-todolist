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
}

struct ContentView: View {
    // 데이터를 담을 변수 만들기
    @State private var newTask = "" // 입력창에 쓸 글자
    @State private var tasks: [TodoItem] = []
    var body: some View {
        // 이 안에서는 다른 화면으로 이동할 수 있다.
        NavigationStack {
        // 2. 화면 배치 시작 (VStack: 위에서 아래로 쌓기
        VStack {
            Text("내 투두 리스트")
                .font(.largeTitle)
                .padding()
            // 3. 입력창과 버튼을 가로로 배치
            HStack {
                TextField ("할 일을 입력하세요...", text: $newTask).textFieldStyle(RoundedBorderTextFieldStyle())
                // 텍스트는 왼쪽, 버튼은 오른쪽으로 밀어주는 역할을 한다.
                Spacer()
                Button("추가") {
                    if !newTask.isEmpty {
                        tasks.append(TodoItem(title: newTask, isDone: false))
                        newTask = ""
                        
                        saveTasks()
                    }
                }
            }
            .padding()
            
            // 4. 리스트 보여주기
            List($tasks) { task in
                HStack {
                    // 지정된 뷰로 이동하는 곳.
                    NavigationLink(destination: DetailView(task: task.title.wrappedValue)) {
                        Text(task.title.wrappedValue)
                    }
                    
                    Spacer()
                    
                    Button(action:{
                        if let index = tasks.firstIndex(of: task.wrappedValue) {
                            tasks.remove(at: index)
                        }
                        saveTasks()
                    }) {
                        Text("🗑️")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
            }.onAppear {
                loadTasks()
            }
            }
        }
        .padding()
    }
    
    // 데이터를 JSON으로 인코딩 해서 저장한다.
    func saveTasks() {
        if let encodedData = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedData, forKey: "SavedTasks")
        }
    }
    
    
    // 데이터를 불러와서 decoded한다.
    func loadTasks() {
        if let savedData = UserDefaults.standard.data(forKey: "SavedTasks") {
            if let decodedTasks = try? JSONDecoder().decode([TodoItem].self, from: savedData){
                tasks = decodedTasks
            }
        }
    }
}

struct DetailView: View {
    let task: String // 목록에서 전달받을 할 일 내용
    
    var body: some View {
        VStack(spacing: 20) {
            Text("상세 내용")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(task) // 전달받은 할일을 크게 보여줌
                .font(.system(size: 40, weight: .bold))
                .padding()
            
            Text("이곳에 나중에 메모나 날짜 기능을 추가할 수 있다.")
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
        }.frame(minWidth: 400, minHeight: 400) // 창 크기 넉넉하게
        
    }
    
}

#Preview {
    ContentView()
}
