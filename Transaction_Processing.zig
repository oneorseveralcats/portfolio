// Description: A port of the Cobol Transaction Processing program into the programming language Zig.

// Imports standard library.
const std = @import("std");

// shorter alias for the ArrayList data structure. Originally my plan was to use slices in Zig. slices
// are a pointer to a memory location and a length. They are fixed length when they are defined. I
// switched to using arraylists because using an iterator loop over a slice won't stop at the end of
// the populated array entries and will cause runtime errors. I could've probably handled it within
// the iterator loop, but that seems messy.
const ArrayList = std.ArrayList;

// shorter alias for string comparison.
const eql = std.mem.eql;

// note: through the comments of this program i will alternate between saying array/slice. if i say
// array i mean slice (which is a pointer bundled with a length).

// alias for the heap page-based memory allocator. In Zig, there are different memory allocators that
// use different memory allocation strategies. Some are more performant than others in different
// contexts, and you can vary which memory allocation strategies you use throughout your program.
//
// i chose the page allocator because it seemed like the simplest. for any amount of requested
// memory, it will ask the os for an entire page. if i were to write a "real" application i'd likely
// be more picky about that. other memory allocators are described here:
// https://zig.guide/standard-library/allocators/
const allocator = std.heap.page_allocator;

// Zig doesn't actually have a regular print statement because there are a lot of assumptions made by
// print statements, and Zig programs try to be explicit with intention. Potential choices with IO:
//   - buffered vs unbuffered
//   - locking or not (in multithreaded situations)
//   - stdout vs stderr
//
// There actually is a print function under std.debug.print, but it feels improper to use for an
// actual program.
//
// Two writers, one for stdout the other for stderr. They are both unbuffered and non-locking.
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

// structs that mimick the different input file structures. unlike in COBOL, there don't have to be
// entries for the whitespace separators.
//
// customer:
//   - customer_id: the unique id of the customer. In Zig strings are "slices" of unsigned 8-bit
//         integers. A slice is a a pointer to a memory location and a length.
//   - customer_name. name of the customer. first and last are split by a _
//   - street_address. the street address associated with the customer.
//   - city. The city associated with the customer.
//   - country_or_state. The country or state associated with the customer. If they're not local to
//         the US, this value will be the name of their country
//   - debt. the amount of money the customer owes.
const customer_struct = struct { customer_id: []const u8, customer_name: []const u8, street_address: []const u8, city: []const u8, country_or_state: []const u8, debt: f32 };

// item:
//   - item_id. the unique id of the item in inventory.
//   - item_name. the name of the item in inventory.
//   - amount_in_stock. the amount of the item that is currently in stock.
//   - amount_to_reorder_at. if the amount in stock gets to this amount, it will be logged.
//   - item_cost. the price of one of the item.
const item_struct = struct { item_id: []const u8, item_name: []const u8, amount_in_stock: u16, amount_to_reorder_at: u16, item_cost: f32 };

// transaction:
//   - customer_id. the unique id of the customer who performed the transaction.
//   - item_id. the unique id of the item the customer purchased.
//   - amount_ordered. the quantity of items that the customer ordered.
//   - discount. a character that indicates what discount the customer should get.
const transaction_struct = struct { customer_id: []const u8, item_id: []const u8, amount_ordered: u16, discount: []const u8 };

// (only the new fields are described below)
// invoice:
//   - customer_name.
//   - item_name.
//   - item_cost.
//   - amount_ordered.
//   - cost_before_discount. the total cost before the discount is applied.
//   - discount_amount. the monetary amount of the discount.
//   - cost_after_discount. the total cost
const invoice_struct = struct { customer_name: []const u8, item_name: []const u8, item_cost: f32, amount_ordered: u16, cost_before_discount: f32, discount_amount: f32, cost_after_discount: f32 };

// the structure of a function in Zig looks like this:
//   pub fn <function-name> (var: Type, var2: Type2) returnType {
//
//   }
//
// - pub is only required on the main function or if you want functions in different files to be able
//       to use your function.
//
// - if your function throws an error (if you use "try" rather than handling an error), you preface
//       the return type with !
//
// - if your function can return either a value or null, you preface your return type with ?
//
//
// Zig forces you to do something with errors in your program otherwise it will not compile. It's a
// pain, but probably results in more reliable programs.
//
// Because Zig functions are incredibly verbose, I've decided to wrap most of them with simpler named
// local functions. The createFile function has two statements that can throw errors; the one that
// creates the file, and the stderr.print statement that informs the user of the file error. It's
// kind of wild that you have to try or catch errors from EVERY print statement.
fn createFile(path: []const u8) std.fs.File {
    return std.fs.cwd().createFile(path, .{}) catch {
        stderr.print("ERROR: unable to create file {s}\n", .{path}) catch {};
        std.process.exit(1);
    };
}

// essentially the same as createFile, but opens a file instead. Also, it is the convention in Zig for
// function names in Zig to be camelCase, and for regular variables to be snake_case.
fn openFile(path: []const u8) std.fs.File {
    return std.fs.cwd().openFile(path, .{}) catch {
        stderr.print("ERROR: No file located at {s}\n", .{path}) catch {};
        std.process.exit(1);
    };
}

// this function just takes a path and creates a file object, then reads all of that file into a buffer
// in memory and then closes the file. All of these little functions probably aren't necessary but i
// think they make the program more readable.
fn openFileAndLoadIntoBuffer(path: []const u8) []const u8 {
    var file = openFile(path);
    defer file.close(); // defer tells the compiler to do this at the end of the current scope

    return file.readToEndAlloc(allocator, std.math.maxInt(usize)) catch {
        stderr.print("ERROR: Something went wrong while reading {s}\n", .{path}) catch {};
        std.process.exit(1);
    };
}

// creates an iterator that returns strings separated by the \n character. since i've read a whole
// file into a buffer this is the way to get individual lines.
fn createLineIterator(buf: []const u8) std.mem.SplitIterator(u8, .scalar) {
    return std.mem.splitScalar(u8, buf, '\n');
}

// creates an iterator that splits a string based on whitespace. one problem with this iterator is if
// there are multiple whitespace characters it will return empty strings between them. that's what
// getWords is for.
fn createWordIterator(line: []const u8) std.mem.SplitIterator(u8, .sequence) {
    return std.mem.split(u8, line, " ");
}

// this function progresses the word_iterator until the string it returns isn't empty. The type of
// iterators is very unwieldy, and it returns a slice of unsigned integers (string). If it doesn't find
// a non-empty string then it throws and error and crashes the program
fn getWord(word_iterator: *std.mem.SplitIterator(u8, .sequence)) []const u8 {
    while (word_iterator.next()) |word| {
        if (word.len != 0) {
            return word;
        }
    }

    stderr.print("ERROR: requested another field on line, but none found\n", .{}) catch {};
    std.process.exit(1);
}

// function that will convert an array of unsigned integers (string) into a 32 bit float value.
// originally i had this inline where it was used, but it was incredibly bulky so broke it out to its
// own helper function.
fn parseF32(value: []const u8) f32 {
    return std.fmt.parseFloat(f32, value) catch {
        stderr.print("ERROR: unable to convert \"{s}\" to f32", .{value}) catch {};
        std.process.exit(1);
    };
}

// function that will convert an array of unsigned integers to a 16 bit unsigned integer.
fn parseU16(value: []const u8) u16 {
    return std.fmt.parseInt(u16, value, 10) catch {
        stderr.print("ERROR: unable to convert \"{s}\" to u16", .{value}) catch {};
        std.process.exit(1);
    };
}

// this function takes in a file buffer that's contents is formatted consistently with the structure
// of customers.dat, populates an arraylist of customer structs then returns the memory address for
// assignment purposes. I could have defined this to take in a customer arraylist as an argument and
// mutate it within the function, but I think that returning a value and assigning it to a local value
// is more readable.
fn populateCustomerArrayList(buf: []const u8) ArrayList(customer_struct) {
    // array list to store customer structs. I have defined it here and return it at the end of the
    // function because I think assignment statements are more readable than mutating parametrs.
    var customers = ArrayList(customer_struct).init(allocator);
    // if i were to put
    //  "defer customers.deinit();"
    // here it would deinitalize the memory of the ArrayList at the end of the function and return an
    // uninitialized list to main.

    // creates iterator that gives access to a line of the customer data buffer. iterator.next() moves
    // to the next line
    var line_iterator = createLineIterator(buf);
    // the line variable stores the current line (i actually kind of like this syntaxt).
    while (line_iterator.next()) |line| {
        // creates another iterator to get the whitespace separated strings on the current line.
        var word_iterator = createWordIterator(line);

        // populates the struct at the current index with the non-empty strings from the current line
        customers.append(customer_struct{
            .customer_id = getWord(&word_iterator),
            .customer_name = getWord(&word_iterator),
            .street_address = getWord(&word_iterator),
            .city = getWord(&word_iterator),
            .country_or_state = getWord(&word_iterator),
            // since the debt field is a float, it has to be converted.
            .debt = parseF32(getWord(&word_iterator)),
        }) catch {
            stderr.print("ERROR: failed to append to the ArrayList customers\n", .{}) catch {};
        };
    }

    return customers;
}

// similar to the populateCustomerArrayList. I feel like there's probably more ability for code reuse
// between the two functions.
fn populateInventoryArrayList(buf: []const u8) ArrayList(item_struct) {
    var inventory = ArrayList(item_struct).init(allocator);
    var line_iterator = createLineIterator(buf);
    while (line_iterator.next()) |line| {
        var word_iterator = createWordIterator(line);

        inventory.append(item_struct{
            .item_id = getWord(&word_iterator),
            .item_name = getWord(&word_iterator),
            .amount_in_stock = parseU16(getWord(&word_iterator)),
            .amount_to_reorder_at = parseU16(getWord(&word_iterator)),
            .item_cost = parseF32(getWord(&word_iterator)),
        }) catch {
            stderr.print("ERROR: failed to append to the ArrayList inventory\n", .{}) catch {};
        };
    }

    return inventory;
}

// searches through the arraylist of customer structs and if the id being searched for matches an entry
// it will return that entry. otherwise it will return null which is handled in the processTransactions
// function.
fn returnCustomerIfExists(customers: *ArrayList(customer_struct), value: []const u8) ?customer_struct {
    for (customers.items) |customer| {
        // std.mem.eql is how strings are compared. above i aliased it to eql.
        if (eql(u8, customer.customer_id, value)) {
            return customer;
        }
    }

    return null;
}

// same as above but for Items. I think i could use comptime template stuff to make these two functions
// the same.
fn returnItemIfExists(inventory: *ArrayList(item_struct), value: []const u8) ?item_struct {
    for (inventory.items) |item| {
        if (eql(u8, item.item_id, value)) {
            return item;
        }
    }

    return null;
}

// takes in a file, and error related information and writes to the error file.
fn writeError(file: std.fs.File, error_type: []const u8, id: []const u8) void {
    file.writer().print("ERROR   {s}   {s:>6}\n", .{ error_type, id }) catch {
        stderr.print("ERROR: unable to write to error file", .{}) catch {};
        std.process.exit(1);
    };
}

// takes in a file and invoice struct and writes to the invoice file.
fn writeInvoice(file: std.fs.File, invoice: invoice_struct) void {
    // {s} - string output
    // {d} - numeric output
    // {_:<} - left align
    // {_:>} - right align
    // {_:>5} - right align, field width is 5
    // {d:.2} - numeric with 2 decimal places
    file.writer().print("{s:<14}   {s:<20}   ${d:>5.2}   {d:>1}   ${d:>6.2}   ${d:>5.2}   ${d:>6.2}\n", invoice) catch {
        stderr.print("ERROR: unable to write to invoices file", .{}) catch {};
        std.process.exit(1);
    };
}

// takes in the item cost and amount ordered and multiplies them. I didn't expect to have so much
// difficulty figuring out how to multiply a float and int in Zig. Since it wants everything to be
// explicit there is no implicit casting.
fn calculateCost(item_cost: f32, amount_ordered: u16) f32 {
    // Didn't expect to have to spend like 20 minutes figuring out how to cast an int to a float.
    return item_cost * @as(f32, @floatFromInt(amount_ordered));
}

// looks a little cleaner than using eql.
fn equals(str1: []const u8, str2: []const u8) bool {
    return eql(u8, str1, str2);
}

// calculates the discount from the letter.
fn calculateDiscount(transaction: transaction_struct, item: item_struct) f32 {
    var discount: f32 = 0;
    const letter = transaction.discount;

    // why does this have to be so ugly in every language 😭
    if (equals(letter, "A")) {
        discount = 0.1 * item.item_cost;
    } else if (equals(letter, "B")) {
        discount = 0.2 * item.item_cost;
    } else if (equals(letter, "C")) {
        discount = 0.25 * item.item_cost;
    } else if (equals(letter, "D")) {
        if (transaction.amount_ordered >= 3) {
            discount = item.item_cost;
        }
    } else if (equals(letter, "E")) {
        if (transaction.amount_ordered >= 2) {
            discount = item.item_cost;
        }
    } else if (equals(letter, "Z")) {
        discount = 0;
    }

    return discount;
}

// calculates the total. I am unsure if these smaller functions are better inline or not. I think
// my processingTransactions function is too monolithic and makes it hard to place all the little
// helper functions near the context in which they're used.
fn calculateTotal(cost: f32, discount: f32) f32 {
    return cost - discount;
}

// updates the customer debt in the customers ArrayList.
fn updateCustomerDebt(customers: *ArrayList(customer_struct), invoice: invoice_struct) void {
    // customer is a constant pointer to the item so it can't be used to change values. You have to
    // have an additional value that counts up along with the loop and use the bound variable to
    // access the original ArrayList.
    for (customers.items, 0..) |customer, index| {
        if (equals(customer.customer_name, invoice.customer_name)) {
            customers.items[index].debt += invoice.cost_after_discount;
        }
    }
}

// updates the item quantity in the inventory array list.
fn updateItemQuantity(inventory: *ArrayList(item_struct), invoice: invoice_struct) void {
    for (inventory.items, 0..) |item, index| {
        if (equals(item.item_name, invoice.item_name)) {
            inventory.items[index].amount_in_stock -= invoice.amount_ordered;
        }
    }
}

// monolithic function that opens the output files, iterates through all the transactions, populates
// a transaction record, and uses the values in that transaction record, the customers ArrayList,
// and the inventory ArrayList to generate invoices and write them to "invoices.dat". Aside from that
// it, also detects errors and logs them to "errors.dat", and updates the debt and item quantity of
// the customers and inventory respectively.
fn processTransactions(customers: *ArrayList(customer_struct), inventory: *ArrayList(item_struct), buf: []const u8) void {
    const file_invoices = createFile("./invoices.dat");
    defer file_invoices.close();

    const file_errors = createFile("./errors.dat");
    defer file_errors.close();

    var line_iterator = createLineIterator(buf);
    while (line_iterator.next()) |line| {
        var is_error = false;

        // populates transaction struct
        var word_iterator = createWordIterator(line);
        const transaction = transaction_struct{
            .customer_id = getWord(&word_iterator),
            .item_id = getWord(&word_iterator),
            .amount_ordered = parseU16(getWord(&word_iterator)),
            .discount = getWord(&word_iterator),
        };

        // gets customer if the customer_id is valid, otherwise null
        const customer = returnCustomerIfExists(customers, transaction.customer_id);

        // this if statement checks if what is returned is null. The if part is ran if there is a value
        // the else is if it's null.
        if (customer) |value| {
            // In Zig, if you don't use the value of a local value you get a compile time error. it
            // turns out that discarding a value is using it. I don't do anything here, because I do
            // all of the invoice calculation later.
            _ = value;
        } else {
            // sets flag and writes to error file.
            is_error = true;
            writeError(file_errors, "CUS", transaction.customer_id);
        }

        // same as the customer but for item_id.
        const item = returnItemIfExists(inventory, transaction.item_id);
        if (item) |value| {
            _ = value;
        } else {
            is_error = true;
            writeError(file_errors, "INV", transaction.item_id);
        }

        // if there wasn't an error, create an invoice struct, do all the calculations and write to
        // file. Also, update the customer.debt and item.amount_in_stock for relevant entries.
        if (!is_error) {
            const cost = calculateCost(item.?.item_cost, transaction.amount_ordered);
            const discount = calculateDiscount(transaction, item.?);

            const invoice = invoice_struct{
                .customer_name = customer.?.customer_name,
                .item_name = item.?.item_name,
                .item_cost = item.?.item_cost,
                .amount_ordered = transaction.amount_ordered,
                .cost_before_discount = cost,
                .discount_amount = discount,
                .cost_after_discount = calculateTotal(cost, discount),
            };

            updateCustomerDebt(customers, invoice);
            updateItemQuantity(inventory, invoice);
            writeInvoice(file_invoices, invoice);
        }
    }
}

// prints out all the customer entries in a nicely formatted way.
fn printCustomers(customers: ArrayList(customer_struct)) void {
    stdout.writeAll("Customer Records\n") catch {};
    for (customers.items) |customer| {
        stdout.print("{s:<5}  {s:<17}   {s:<18}   {s:<11}   {s:<10}   ${d:>6.2}\n", customer) catch {};
    }
    stdout.writeAll("\n\n") catch {};
}

// prints out all of the item entries in a nicely formatted way. Also checks to see which items need
// to be restkoced and prints them after.
fn printInventory(inventory: ArrayList(item_struct)) void {
    var items_to_restock = ArrayList([]const u8).init(allocator);
    stdout.writeAll("Inventory Records\n") catch {};
    for (inventory.items) |item| {
        if (item.amount_in_stock <= item.amount_to_reorder_at) {
            items_to_restock.append(item.item_name) catch {};
        }
        stdout.print("{s:<6}   {s:<21}   {d:>2}   {d:>2}   ${d:>5.2}\n", item) catch {};
    }

    stdout.writeAll("\n\n") catch {};

    for (items_to_restock.items) |item| {
        stdout.print("ATTENTION: {s} needs restocked.\n", .{item}) catch {};
    }
}

// main function has to be public. It returns the union type of Error!void. If you handle an error
// with "try" instead of "catch", then you have to mark the return type with !, and, if you use the
// value, in the calling function you have to handle the error there.
//
// Another way aside from try or catch to handle errors is with a specific "if" statement:
//
// var = canThrowError();
// if (var) |value| {
//   doSomething(value);
// }
// else |err| {
//   handle(err);
// }
pub fn main() !void {
    // the most annoying thing about Zig is a program won't compile if:
    //   - there is a local variable or constant that is defined but not use
    //         (_ = <var>; is a way around this)
    //   - there is a local variable that is not mutated (it will tell you to use const)
    //
    // these essentially just call a function to open the input files, load their content into buffers
    // in memory, close those files, and return the buffers. After each function call there is a defer
    // statement which just means it will deallocate the memory of those buffers at the end of the
    // current scope. Since this is the main function, deallocating probably doesn't matter but it
    // seems like Best Practices™. I really like the defer keyword because it keeps the allocation
    // and deallocation of resources right next to each other so you don't have to scroll all the way
    // to the bottom of the file and check every one.
    const file_customers = openFileAndLoadIntoBuffer("./customers.dat");
    defer allocator.free(file_customers);

    const file_inventory = openFileAndLoadIntoBuffer("./inventory.dat");
    defer allocator.free(file_inventory);

    const file_transactions = openFileAndLoadIntoBuffer("./transactions.dat");
    defer allocator.free(file_transactions);

    // since these are mutated, they are "var" instead of "const"
    var customers: ArrayList(customer_struct) = populateCustomerArrayList(file_customers);
    defer customers.deinit();

    var inventory: ArrayList(item_struct) = populateInventoryArrayList(file_inventory);
    defer inventory.deinit();

    // since customers and inventory get modified, their memory references have to be passed in. Nice
    // to have a refresher on pointers I suppose...
    processTransactions(&customers, &inventory, file_transactions);

    printCustomers(customers);
    printInventory(inventory);
}
