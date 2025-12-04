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

// Codable은 데이터 저장을 위해서
struct TaskMemo: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var createdAt: Date = .init() // 시간 계산 용이
    var startTime: Date?
    var endTime: Date?
    var memo: String // 텍스트 데이터를 저장하는 표준 타입
}

@Observable
class TaskMemoStore {
    var taskMemos: [TaskMemo] = []

    func addTaskMemo(title: String, memo: String) {
        let taskMemo = TaskMemo(title: title, memo: memo)
        taskMemos.append(taskMemo)
        print(taskMemo)
        saveTaskMemos()
    }

    func saveTaskMemos() {
        if let encodedData = try? JSONEncoder().encode(taskMemos) {
            UserDefaults.standard.set(encodedData, forKey: "SavedTaskMemos")
        }
    }

    func removeTask(task: TaskMemo) {
        if let index = taskMemos.firstIndex(of: task) {
            taskMemos.remove(at: index)
        }

        saveTaskMemos()
    }

    func loadTasks() {
        if let savedData = UserDefaults.standard.data(forKey: "SavedTaskMemos") {
            if let decodedTasks = try? JSONDecoder().decode([TaskMemo].self, from: savedData) {
                taskMemos = decodedTasks
            }
        }
    }
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

    @State private var taskMemoStore = TaskMemoStore()

    var body: some View {
        // 이 안에서는 다른 화면으로 이동할 수 있다.

        NavigationStack {
            // 2. 화면 배치 시작 (VStack: 위에서 아래로 쌓기
            VStack {
                HStack {
                    Spacer()
                    VStack {
                        NavigationLink(destination: ManualView(taskMemoStore: $taskMemoStore)) {
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

                // 4. 리스트 보여주기

                List {
                    ForEach($taskMemoStore.taskMemos) { $taskMemo in
                        HStack {
                            Text(taskMemo.createdAt, style: .date)
                            NavigationLink(taskMemo.title) {
                                DetailView(taskMemo: $taskMemo)
                            }
                            Spacer()
                            if let startTime = taskMemo.startTime {
                                Text("start:")
                                Text(startTime, style: .time)
                            }
                            if let endTime = taskMemo.endTime {
                                Text("end:")
                                Text(endTime, style: .time)
                            }
                        }.contextMenu {
                            Button(role: .destructive) {
                                taskMemoStore.removeTask(task: taskMemo)
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                }
                .onAppear {
                    taskMemoStore.loadTasks()
                }
            }
        }.onChange(of: taskMemoStore.taskMemos) {
            taskMemoStore.saveTaskMemos()
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
    @Binding var taskMemo: TaskMemo // 데이터 연결

    @State private var showConfetti: Bool = false
    @State var isEditing: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 20) { // 1. 왼쪽 정렬 & 간격 띄우기
            HStack {
                Text(taskMemo.title)
                    .font(.title) // 맥에서는 largeTitle보다 title이 적당할 때가 많음
                    .bold() // 제목은 굵게 강조
                Spacer()
                Text(taskMemo.createdAt, style: .date)
            }

            Divider() // 2. 제목과 내용 사이 구분선

            ScrollView { // 내용이 길어질 수 있으니 스크롤 가능하게
                if isEditing {
                    TextEditor(text: $taskMemo.memo).font(.body).frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(taskMemo.memo)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false) // 터치 무시 (애니메이션 중에도 조작 가능하게)
                }
            }
            HStack {
                Button(action: {
                    isEditing.toggle()
                }) {
                    Text(isEditing ? "완료" : "수정하기") // 상태에 따라 글자 변경
                        .font(.default)
                        .foregroundColor(.white) // 글자색 흰색
                        .padding() // 글자 주변 여백 확보
                        .cornerRadius(10) // 모서리 둥글게
                }.buttonStyle(.plain)

                if taskMemo.startTime == nil {
                    Button(action: {
                        taskMemo.startTime = Date.now
                    }) {
                        Text("작업 시작 !") // 상태에 따라 글자 변경
                            .font(.default)
                            .foregroundColor(.white) // 글자색 흰색
                            .padding() // 글자 주변 여백 확보
                            .cornerRadius(10) // 모서리 둥글게
                    }.buttonStyle(.plain)
                }
                if taskMemo.startTime != nil && taskMemo.endTime == nil {
                    Button(action: {
                        taskMemo.endTime = Date.now

                        // (2) 빵빠레 터뜨리기!
                        showConfetti = true

                        // (3) 0.8초만 기다렸다가 창 닫기 (애니메이션 볼 시간 주기)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {}
                    }) {
                        Text("작업 종료 !") // 상태에 따라 글자 변경
                            .font(.default)
                            .foregroundColor(.white) // 글자색 흰색
                            .padding() // 글자 주변 여백 확보
                            .background(Color.teal)
                            .cornerRadius(10) // 모서리 둥글게
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300) // 창 크기 설정
        .navigationTitle("상세 정보")
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
    @Binding var taskMemoStore: TaskMemoStore
    // 1. 스위치
    @State private var showTemplate = false
    // 2. 템플릿에 들어갈 내용 (데이터) - 여기서 관리해야 사라지지 않는다.
    @State private var templateContent = "Entry Point: \n\n\nExit Point:\n\n"
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
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
                Button(action: {
                    showTemplate = true // 스위치 켜기!
                }) {
                    ProcessCard(
                        step: "STEP 1",

                        title: "예측 및 그리기",

                        description: "Entry Point와 Exit Point만 적는다.\n나머지는 앞으로 채울 것.",

                        icon: "map.fill",

                        color: .purple
                    )
                }.sheet(isPresented: $showTemplate) {
                    TemplateEditorView(text: $templateContent, store: $taskMemoStore)

                }.buttonStyle(.plain) // 버튼 티 안나게 만듬. 기본값은 입체적인 버튼

                // 화살표 (흐름을 보여줌)

                Image(systemName: "arrow.down")

                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.5))

                // STEP 2. 파일 수집

                ProcessCard(
                    step: "STEP 2",
                    title: "파일 수집",
                    description: "관련된 파일 이름 목록을 메모장에 적고\n하나씩 확인한다.",
                    icon: "folder.fill",
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

struct TemplateEditorView: View {
//    @Environment(TaskStore.self) var store
    // 부모가 빌려준 노트 (@Binding)
    @Binding var text: String
    @Binding var store: TaskMemoStore

    @State private var title: String = ""

    @State private var showConfetti: Bool = false
    // 창을 닫기 위한 도구 (환경 변수)
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            VStack(spacing: 25) {
                Text("아키텍처 작성")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top)

                HStack {
                    Text("목표: ")
                    TextField("구현 목표를 적으세요", text: $title)
                        .textFieldStyle(.roundedBorder)

                }.padding()

                TextEditor(text: $text)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(Color(red: 0.25, green: 0.25, blue: 0.26).cornerRadius(10))
                    .foregroundColor(Color(nsColor: .textColor)) // 글자색은 기본(흰색/검정)으로
                    .frame(height: 300)
                    .padding(10)

            }.navigationTitle("템플릿 작성")
                .toolbar {
                    Button("완료") {
                        // (1) 데이터 저장
                        store.addTaskMemo(title: title, memo: text)

                        // (2) 빵빠레 터뜨리기!
                        showConfetti = true

                        // (3) 0.8초만 기다렸다가 창 닫기 (애니메이션 볼 시간 주기)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            title = ""
                            text = ""
                            dismiss()
                        }
                    }
                }
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false) // 터치 무시 (애니메이션 중에도 조작 가능하게)
            }
        }
    }
}

struct ConfettiView: View {
    @State private var isAnimating = false
    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]

    var body: some View {
        ZStack {
            ForEach(0 ..< 50, id: \.self) { _ in
                Circle()
                    .fill(colors.randomElement()!)
                    .frame(width: 8, height: 8)
                    .modifier(ConfettiParticle(isAnimating: isAnimating))
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// 파티클 움직임을 담당하는 수식어
struct ConfettiParticle: ViewModifier {
    let isAnimating: Bool
    @State private var randomX: CGFloat = .random(in: -100 ... 100)
    @State private var randomY: CGFloat = .random(in: -100 ... 100)
    @State private var randomScale: CGFloat = .random(in: 0.5 ... 1.5)

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? randomScale : 0.1)
            .offset(x: isAnimating ? randomX : 0, y: isAnimating ? randomY : 0)
            .opacity(isAnimating ? 0 : 1)
            .animation(.easeOut(duration: 1.0), value: isAnimating)
    }
}

#Preview {
    ContentView()
}
