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
                HStack {
                    Spacer()

                    VStack {
                        NavigationLink(destination: ManualView()) {
                            Text("🛠️ 로직 분석 메뉴얼")

                                .cornerRadius(10)
                        }

                        NavigationLink(destination: MedicineView()) {
                            Text("💊 골이 아픈것 같으면 누르세요")

                                .cornerRadius(10)
                        }
                    }
                }

                // 아키텍처 간단하게 적고, 조금씩 쌓아가면서 개발

                Text("작업목록")

                    .font(.largeTitle)
                    .padding()

                // 3. 입력창과 버튼을 가로로 배치

                HStack {
                    HStack {
                        Text("할 일:")

                        TextField("할 일을 입력하세요...", text: $newTask).textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    Spacer()

                    Button("추가") {
                        saveTask()
                    }

                }.onSubmit {
                    saveTask()
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

    private func saveTask() {
        if !newTask.isEmpty {
            taskStore.addTask(title: newTask)

            newTask = ""
        }
    }
}

struct DetailView: View {
    @Binding var task: TodoItem // 목록에서 전달받을 할 일 내용

    @State private var newSubtaskTitle: String = ""

    var body: some View {
        VStack {
            Text("\(task.title)")
                .font(.largeTitle)
                .foregroundColor(.gray)

            HStack {
                TextField("플로우", text: $newSubtaskTitle).padding()

                Button("세부 할일 추가") {
                    saveSubtask()

                }.padding()

            }.onSubmit {
                saveSubtask()
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

    private func saveSubtask() {
        let newSubtask = SubTask(title: newSubtaskTitle, isDone: false, memo: "")

        task.subTasks.append(newSubtask)

        newSubtaskTitle = ""
    }
}

struct MedicineView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🧐 필독")

                .font(.largeTitle) // 제일 큰 폰트
                .fontWeight(.bold) // 굵게
                .padding(.bottom, 10) // 아래 여백 살짝

            // 1. 증상 (빨간 알약)

            VStack(alignment: .leading, spacing: 5) {
                Text("🔥 증상").font(.headline)

                Text("CPU 과열 및 RAM 부족")
            }

            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.1))
            .cornerRadius(20) // 알약 모양 핵심

            // 2. 원인 (파란 알약)

            VStack(alignment: .leading, spacing: 5) {
                Text("🧐 원인").font(.headline)

                Text("1. 인지적 구두쇠 (빨리 끝내려는 욕심)")

                Text("2. 불안의 회피 (생각하는 고통의 회피)")

                Text("3. 간헐적 강화 (운 좋게 성공한 기억)")
            }

            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)

            // 3. 처방 (초록 알약)

            VStack(alignment: .leading, spacing: 5) {
                Text("💊 처방").font(.headline)

                Text("1. RAM 부족 → 메모장/외부 툴에 기록")

                Text("2. 시스템 부재 → 멈추고 설계하는 습관 들이기")
            }

            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
        }

        .padding()
    }
}

struct ManualView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // 헤더

                VStack(spacing: 10) {
                    Text("🛠️ 코드 분석 매뉴얼")

                        .font(.largeTitle)
                        .fontWeight(.heavy)

                    Text("복잡한 로직을 분석하는 3단계")

                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                .padding(.bottom, 20)

                // STEP 1. 예측 및 그리기

                ProcessCard(
                    step: "STEP 1",

                    title: "예측 및 그리기",

                    description: "Entry Point와 Exit Point만 적는다.\n나머지는 앞으로 채울 것.",

                    icon: "map.fill",

                    color: .purple
                )

                // 화살표 (흐름을 보여줌)

                Image(systemName: "arrow.down")

                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.5))

                // STEP 2. 파일 수집

                ProcessCard(
                    step: "STEP 2",

                    title: "파일 수집",

                    description: "관련된 파일 이름 목록을 메모장에 적고\n하나씩 확인한다.",

                    icon: "folder.fill", // 또는 doc.text.magnifyingglass

                    color: .orange
                )

                // 화살표

                Image(systemName: "arrow.down")

                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.5))

                // STEP 3. 검증 및 수정

                ProcessCard(
                    step: "STEP 3",

                    title: "로직 검증 및 수정",

                    description: "로직을 읽으며 예측이 맞는지 확인/수정.\nCall Stack은 메모장에 적으며 내려가자.",

                    icon: "checkmark.shield.fill",

                    color: .blue
                )
            }

            .padding()
        }
    }
}

// 반복되는 카드 디자인을 위한 헬퍼 뷰

struct ProcessCard: View {
    let step: String

    let title: String

    let description: String

    let icon: String

    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // 왼쪽: 아이콘 및 스텝 표시

            VStack(spacing: 5) {
                ZStack {
                    Circle()

                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)

                        .font(.title2)
                        .foregroundColor(color)
                }

                Text(step)

                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            // 오른쪽: 내용

            VStack(alignment: .leading, spacing: 5) {
                Text(title)

                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(description)

                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true) // 줄바꿈 잘 되도록
                    .lineSpacing(4) // 줄 간격 살짝 띄우기
            }

            Spacer()
        }

        .padding()
        .background(Color.black) // 배경색
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // 그림자 효과
    }
}

#Preview {
    ContentView()
}
