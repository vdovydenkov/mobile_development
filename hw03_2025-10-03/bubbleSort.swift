// Основная функция сортировки: принимает числовой массив, возвращает отсортированный массив
// Метод сортировки - пузырьком
func sortArray(_ arr: [Int]) -> [Int] {
    // Проверяем размер массива: имеет ли смысл его сортировать
    if arr.count < 2 { 
        return arr
    }
    // Делаем копию массива
    var arr = arr
    var tmpStack: Int  // понадобится для обмена значениями между элементами
    // Проходимся по элементам массива до предпоследнего
    for globalCounter in 0...arr.count-2 {
        // Второй цикл по оставшимся элементам, включая последний
        for counter in globalCounter+1...arr.count-1 {
            if arr[globalCounter] > arr[counter] {
                // Меняем элементы местами
                tmpStack = arr[globalCounter]
                arr[globalCounter] = arr[counter]
                arr[counter] = tmpStack
            }
        }
    }
    return arr
}

// Генератор массива случайных значений чисел от 0 до 1000
func generateRandValues(count: Int) -> [Int] {
    var randomArray: [Int] = []
    for _ in 1...count {
        randomArray.append(Int.random(in: 0...100))
    }
    return randomArray
}

let srcArray = generateRandValues(count: 8)
let result = sortArray(srcArray)

print("Исходный:        \(srcArray)")
print("Отсортированный: \(result)")
