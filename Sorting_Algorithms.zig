// Description:  Bubble Sort, Insertion Sort, Selection Sort, Heap Sort, and Quicksort implemented in the
// programing language Zig. 
// 
// Imports standard library
const std = @import("std");

// Zig doesn't actually have a regular print statement because there are a lot of implicit assumptions
// made by print statements, and Zig programs try to be explicit with intention.
//
// Two writers, one for stdout the other for stderr. I am going to try and use the correct one for each
// purpose.
var stdout = std.io.getStdOut().writer();
var stderr = std.io.getStdErr().writer();

// returns true if array has 0 or 1 elements. Makes some algorithms work with the empty list and others
// just more efficient.
fn isArrayEmptyOrSinglet(array: []i32) bool {
    return array.len <= 1;
}

// swaps the values of two variables. Used in a few sorting algorithms to swap array values.
fn swap(i: *i32, j: *i32) void {
    const temp = i.*;
    i.* = j.*;
    j.* = temp;
}

// BubbleSort. Each pass will array items with the items next to them if they're larger than their
// neighbor to the right or smaller than their neighbor to the left. The algorithm runs enough times
// for the entire list to be sorted.
//
// An example execution:
//
//   5 4 3 2 1 (5 < 4)
//   4 5 3 2 1 (5 < 3)
//   4 3 5 2 1 (5 < 2)
//   4 3 2 5 1 (5 < 1)
//   4 3 2 1 5 (4 < 3)
//   3 4 2 1 5 (4 < 2)
//   3 2 4 1 5 (4 < 1)
//   3 2 1 4 5 (4 < 5) false
//   3 2 1 4 5 (3 < 2)
//   2 3 1 4 5 (3 < 1)
//   2 1 3 4 5 (3 < 4) false
//   2 1 3 4 5 (2 < 1)
//   1 2 3 4 5 (2 < 3) false
fn bubbleSort(array: []i32) []i32 {
    if (isArrayEmptyOrSinglet(array)) {
        return array;
    }

    var is_sorted = false;

    while (!is_sorted) {
        is_sorted = true;

        // if the list is iterated over and nothing to the right is smaller than the value to its left
        // then the list is sorted, otherwise the flag will be unset and after moving entries the array
        // will be traversed again.
        for (0..(array.len - 1)) |i| {
            if (array[i] > array[i + 1]) {
                swap(&array[i], &array[i + 1]);
                is_sorted = false;
            }
        }
    }

    return array;
}

// InsertionSort. The sort picks and element and begins to compare it with elements lower down in the
// array. As it compares it shifts elements to the right until it finds the place for the element it
// has and inserts it. After that it moves to the next element and does the same process until the
// list is sorted.
fn insertionSort(array: []i32) []i32 {
    if (isArrayEmptyOrSinglet(array)) {
        return array;
    }

    for (1..array.len) |index| {
        const temp = array[index];
        var location = index;

        while (location > 0 and array[location - 1] > temp) : (location -= 1) {
            array[location] = array[location - 1];
        }
        array[location] = temp;
    }

    return array;
}

// SelectionSort. It iterates through the list and chooses the smallest element and swaps it with
// the left-most element in the unsorted part of the list.
fn selectionSort(array: []i32) []i32 {
    if (isArrayEmptyOrSinglet(array)) {
        return array;
    }

    for (0..(array.len - 1)) |index| {
        var min = array[index];
        var minIndex = index;

        for (index + 1..array.len) |jndex| {
            if (array[jndex] < min) {
                min = array[jndex];
                minIndex = jndex;
            }
        }

        swap(&array[index], &array[minIndex]);
    }

    return array;
}

// HeapSort. Does not work. The usize integers make this one a pain because of how may different calls
// there are to the heapify function.
fn heapSort(array: []i32, n: usize) void {
    if (!isArrayEmptyOrSinglet(array)) {
        var i = n / 2 - 1;
        // originally was : i>=0
        while (i > 0) : (i -= 1) {
            heapify(array, n, i);
        }

        i = n - 1;
        // originally was : i>=0
        while (i > 0) : (i -= 1) {
            // originally was i
            swap(&array[0], &array[i - 1]);
        }
    }
}

fn heapify(array: []i32, n: usize, i: usize) void {
    var largest = i;
    const left = 2 * i + 1;
    const right = 2 * i + 2;

    if (left < n and array[left] > array[largest]) {
        largest = left;
    } else if (right < n and array[right] > array[largest]) {
        largest = right;
    }

    if (largest != i) {
        swap(&array[i], &array[largest]);
        heapify(array, n, largest);
    }
}

// QuickSort. Quicksort chooses a pivot value then sorts the list into smaller on one side of the pivot
// value, larger on the other. It continues to recursively call itself until the sublists it's dealing
// with are empty, then the recursive calls return and the list is sorted.
fn quickSort(array: []i32, low: usize, high: usize) void {
    if (!isArrayEmptyOrSinglet(array)) {
        if (low < high) {
            const pivot = partition(array, low, high);
            // Zig uses the type usize to index arrays. usize are only positive integers, and overflow
            // if negative. This prevents that overflow.
            if (pivot > 0) {
                quickSort(array, low, pivot - 1);
            }
            quickSort(array, pivot + 1, high);
        }
    }
}

fn partition(array: []i32, low: usize, high: usize) usize {
    const pivot = array[high];
    var i = low;

    for (low..high) |jndex| {
        if (array[jndex] < pivot) {
            swap(&array[i], &array[jndex]);
            i += 1;
        }
    }
    swap(&array[i], &array[high]);
    return i;
}

// used to print out the sorted lists.
fn printSlice(slice: []i32) void {
    stdout.print("{s} ", .{"{"}) catch {};

    for (slice) |n| {
        stdout.print("{d} ", .{n}) catch {};
    }
    stdout.print("{s}\n", .{"}"}) catch {};
}

// main is public (pub), returns nothing (void), and can throw errors (!).
pub fn main() !void {
    var array1 = [_]i32{};
    var array2 = [_]i32{1};
    var array3 = [_]i32{ 1, 2, 3, 4, 5 };
    var array4 = [_]i32{ 5, 4, 3, 2, 1 };
    var array5 = [_]i32{ 9, 3, 5, 1, 7, 2, 8, 1, 4, 11 };

    // printSlice(bubbleSort(&array1));
    // printSlice(bubbleSort(&array2));
    // printSlice(bubbleSort(&array3));
    // printSlice(bubbleSort(&array4));
    // printSlice(bubbleSort(&array5));

    // printSlice(selectionSort(&array1));
    // printSlice(selectionSort(&array2));
    // printSlice(selectionSort(&array3));
    // printSlice(selectionSort(&array4));
    // printSlice(selectionSort(&array5));

    // printSlice(insertionSort(&array1));
    // printSlice(insertionSort(&array2));
    // printSlice(insertionSort(&array3));
    // printSlice(insertionSort(&array4));
    // printSlice(insertionSort(&array5));

    // printSlice(heapSort(&array1));
    // printSlice(heapSort(&array2));
    // printSlice(heapSort(&array3));
    // printSlice(heapSort(&array4));
    // printSlice(heapSort(&array5));

    // heapSort(&array1, array1.len);
    // heapSort(&array2, (array2.len));
    // heapSort(&array3, (array3.len));
    // heapSort(&array4, (array4.len));
    // heapSort(&array5, (array5.len));
    // printSlice(&array1);
    // printSlice(&array2);
    // printSlice(&array3);
    // printSlice(&array4);
    // printSlice(&array5);

    // quickSort(&array1, 0, array1.len);
    // quickSort(&array2, 0, (array2.len - 1));
    // quickSort(&array3, 0, (array3.len - 1));
    // quickSort(&array4, 0, (array4.len - 1));
    // quickSort(&array5, 0, (array5.len - 1));
    // printSlice(&array1);
    // printSlice(&array2);
    // printSlice(&array3);
    // printSlice(&array4);
    // printSlice(&array5);
}
