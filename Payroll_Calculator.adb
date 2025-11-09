--  Program:      Payroll in Ada
-- 
--  Description:  An application that calculates payroll from two records; one containing employee
--                information, and the other containing the id of the employee, hours worked, and
--                deductions.
--
-- Compiler:      GNAT 13.3.0 (NixOS)




-------------
-- Imports --
-------------
With Ada.Text_IO; use Ada.Text_IO; 
With Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
With Ada.Float_Text_IO; use Ada.Float_Text_IO;

-- Needed for Trim and Both (used in Trim)
With Ada.Strings; use Ada.Strings;
With Ada.Strings.Fixed; use Ada.Strings.Fixed;


procedure Program is
   -----------------------
   -- Type Declarations --
   -----------------------
   
   -- Declaration for the employee record type. The fields are:
   --   ID         - employee id
   --   Name       - name of the employee. Formatted First_Last
   --   Wages      - hourly wage
   --   Dependents - number of dependents the employee has.
   type Employee_Record is
      record
         ID         : String(1..7);
         Name       : String(1..21);
         Wages      : Float;
         Dependents : Integer;
      end record;
   -- oddly enough it seems like String variables in GNAT that are defined `String(1..n)` have to be
   -- n characters long, otherwise there's a compile length error. I initially solved that problem
   -- for name by defining it as an Unbounded_String, but changed to using Move(Source, Target) when
   -- assigning values to it in hopes of fixing an output error I was getting later.

   -- array type that contains employee records. The range is unspecified so instances of the type
   -- have to specify them.
   type Employee_Array is array (Integer range <>) of Employee_Record;
   

   -- Declaration for the transaction record. The fields are:
   --   id    - employee id
   --   hours - the amount of hours an employee worked
   --   fee   - a single character code that represents a certain amount to be subtracted from the
   --           employee's wages.
   type Transaction_Record is
      record
         ID    : String(1..7);
         Hours : Integer;
         Fee   : Character;
      end record;

   -- Payroll Record. Holds calculations for gross pay, taxes, fees, net pay for the current
   -- transactions.
   type Payroll_Record is
      record
         Name : String(1..21);
         Gross_Pay : Float;
         Tax       : Float;
         Fee       : Float;
         Net_Pay   : Float;
      end record;

   -- Summary Record. It keeps running totals for all the values that will be printed in the summary
   -- out file. The field names are pretty self explanatory.
   type Summary_Record is
      record
         Gross_Pay : Float;
         Tax       : Float;
         Fee       : Float;
         Net_pay   : Float;
         Num_Transactions : Integer;
      end record;
   -- The Summary Record is very similar to the Payroll_Record so there's probably some way to
   -- condense them to a single record type. That feels like it would be sloppy though.





   ---------------------------
   -- Variable Declarations --
   ---------------------------
   
   -- Ada style guide seems to suggest using Mixed Snake Case for variables
   -- (https://www.adaic.org/resources/add_content/docs/95style/html/sec_3/3-2-1.html)

   -- declare an array type Employee_Array that will be populated from emp.txt
   Employees : Employee_Array(1..20);

   -- keep track of number of employees in employees array.
   Num_Employees : Integer;

   -- Declare the paths of the input and output files
   In_Employees_Path : constant String := "emp.txt";
   In_Payroll_Path   : constant String := "payroll.txt";
   Out_EmployeePay_Path : constant String := "employee_pay.txt";
   Out_Summary_Path     : constant String := "summary.txt";
   -- I decided to declare the file paths as constants because, if this were a real program, it
   -- seems very possible that the files you would read from/write too would change. Defining the
   -- paths this way discourages hardcoding values which would make the program easier to extend
   -- in the future.

   -- Declaration of the variables that the input and output files are accessed through.
   In_Employees : File_Type;
   In_Payroll   : File_Type;
   Out_EmployeePay : File_Type;
   Out_Summary     : File_Type;

   -- for debugging. Shows more information from procedures when turned on.
   Verbose : Boolean := False;



   -----------------
   -- Subroutines --
   -----------------

   -- Populates the array of employee records from the emp.txt input file.
   procedure Populate_Employees (inFile : out FILE_TYPE; inPath : String;
                                 arr : out Employee_Array; count : out Integer) is
   begin
      -- open the file that will be read into the array `arr`
      Open(inFile, In_File, inPath);

      -- For debugging purposes. I'm not sure the best approach to sectioning off debugging code. I
      -- have noticed that when debugging I will often add lines, remove lines, comment them out,
      -- etc. This just seemed like a much more elegant solution.
      if Verbose then
         New_Line(2);
         Put_Line("Populating Employees Array");
         New_Line(1);
      end if;
      -- (This approach to debugging didn't last. If you have a single switch for all debugging it
      --  makes it harder to debug specific things.)

      -- Initializes count to 0. It will be incremented at the very beginning of the loop to 1. I
      -- initially had this declared and initialized at the top, but it is probably more readable to
      -- initialize it here so that most of the relevant information is near where the variable is
      -- being used.
      count := 0;

      -- loop until the file has been completely read. After that, `arr` will be fully populated
      -- from inFile.
      while not End_Of_File(inFile) loop

         -- count is the index for `arr`. count is initialized to 0 above and then incremented
         -- before being used in order to have the correct count.
         count := count + 1;

         -- Reading strings in this way automatically pads them with " ". If using a regular string
         -- and the assignment is not exact then there will be a runtime "length check" error.
         Move(Get_Line(inFile), arr(count).ID);
         Move(Get_Line(inFile), arr(count).Name);

         -- reading in the float for wages. Because this is Get instead of Get_Line it requires
         -- skipping to the next line for the next read.
         Get(inFile, arr(count).Wages);
         Skip_Line(inFile);

         -- reading in the integer for dependents. The Skip_Line function has to be wrapped in an if
         -- statement because on the last line of the file it will throw an error that will kill the
         -- program.
         Get(inFile, arr(count).Dependents);
         if not End_Of_File(inFile) then
            Skip_Line(inFile);
         end if;


         -- for debugging purpose. Just prints out all values in the current record each iteration
         -- of the loop. It's mostly to just check to make sure that all values are being saved
         -- correctly.
         if Verbose then
            Put_Line(arr(count).ID);
            Put_Line(Employees(count).Name);

            -- Put(source, space before decimal, space after decimal, exponent to show)
            Put(arr(count).Wages, 4, 2, 0);
            New_Line(1);

            -- Put(source, width)
            Put(arr(count).Dependents, 0);
            New_Line(1);

            Put(count);
            New_Line(1);
         end if;
      end loop;

      -- closes the input file.
      Close(inFile);
   end Populate_Employees;





   -- Processes all the transactions in payroll.txt, outputs the payroll information for each
   -- transaction to a file, then outputs the summary of all transactions to a summary file.
   procedure Process_Transactions_and_Output_To_Files (inFile : out FILE_TYPE; inPath : String;
                                                       payroll_file : out FILE_TYPE; payroll_path : String;
                                                       summary_file : out FILE_TYPE; summary_path : String;
                                                       arr : Employee_Array; count : Integer) is
      ---------------------
      -- Local variables --
      ---------------------

      -- integer to store index if employee id is valid is found.
      Index : Integer;

      -- record to store the employee data if index is found.
      Employee : Employee_Record;

      -- record to be used to store the transaction being processed in. It's defined within this
      -- procedure rather than the main procedure because it is only used in this procedure. It
      -- seems better to define things as locally as possible.
      Transaction : Transaction_Record;

      -- Holds the payroll calculations for the current transaction. That includes gross pay, taxes,
      -- fees, and net pay.
      Payroll : Payroll_Record;

      -- record to be used to store the running totals for gross pay, taxes, fees, and net pay.
      Running_Total : Summary_Record;





      -----------------------
      -- Local Subroutines --
      -----------------------

      -- takes an array of employee records, the number of employee records, and the payroll id. if
      -- the payroll id matches an employee id in the array, the array index will be returned. If
      -- not then -1 will be return.
      --
      -- Given that the range of array indexes can be anything, this function may return the wrong
      -- results if the range of array indexes includes -1.
      function Return_Employee_Index_If_Exists (arr : Employee_Array; count : Integer;
                                                id : String) return Integer is
      begin
         -- for loop iterates through all populated indicies of the array. 
         for I in 1 .. count loop
            -- if the Employee ID in the current array index matches the one from the transaction
            -- then returns index
            if arr(I).ID = id then
               return I;
            end if;
         end loop;

         -- otherwise returns -1.
         return -1;
      end Return_Employee_Index_If_Exists;

      -- Computes the Gross pay from hours and wages. It has a helper predicate function that tells
      -- Compute_Gross_Pay if it needs to take overtime into account.
      function Compute_Gross_Pay (hours: Integer; wages: Float) return Float is
         -- Holds the value calculated for gross pay. I used a local variable so that I could have
         -- a single return at the bottom of the function. It seemss like a good practice (that I
         -- don't follow for Is_Overtime).
         Gross_Pay : Float;

         -- Checks to see if overtime (over 40 hours) bonus should be applied. It's probably more
         -- confusing and less readable to write it this way instead of putting it in the body of
         -- Compute_Gross_Pay. I think the Ada syntax makes small functions not as worth it as, say,
         -- a language like python.
         function Is_Overtime (hours : Integer) return Boolean is
         begin
            -- There is overtime.
            if hours > 40 then
               return True;
            end if;

            -- There isn't any overtime.
            return False;
         end Is_Overtime;
      begin
         -- If there isn't overtime calculate simple gross_pay. Else, do the overtime calculation.
         if not Is_Overtime(hours) then
            Gross_Pay := Float(hours) * wages;
         else 
            Gross_Pay := 40.0 * wages + Float(hours - 40) * 1.5 * wages;
         end if;

         -- Return the calculated gross pay.
         return Gross_Pay;
      end Compute_Gross_Pay;

      -- Function to calculate the amount of taxes.
      function Compute_Tax (gross_pay : Float; dependents : Integer) return Float is
         -- Local variables that allow the calculations to be done at the bottom of the function
         -- instead of in every conditional.
         Tax_Rate : Float;
         Tax      : Float;
      begin
         -- This feels very ugly. I tried to use a case statement but does not seem designed for
         -- floats. As far as I'm aware it works though!
         --
         -- It essentially just returns the appropriate tax rate for every tax bracket based on the
         -- table provided in the assignment.
         if gross_pay >= 0.0 and gross_pay <= 199.99 then
            Tax_Rate := 0.00;
         elsif gross_pay <= 349.99 then
            Tax_Rate := 0.08;
         elsif gross_pay <= 499.99 then
            Tax_Rate := 0.13;
         elsif gross_pay <= 549.99 then
            Tax_Rate := 0.18;
         elsif gross_pay <= 599.99 then
            Tax_Rate := 0.20;
         elsif gross_pay <= 649.99 then
            Tax_Rate := 0.23;
         elsif gross_pay <= 699.99 then
            Tax_Rate := 0.27;
         elsif gross_pay <= 899.99 then
            Tax_Rate := 0.30;
         elsif gross_pay >= 900.00 then
            Tax_Rate := 0.35;
         else
            -- This would be if you got a negative tax rate. I don't think it's strictly necessary
            -- because I believe the if below would make it 0 anyways, but probably better to try to
            -- handle all potential inputs.
            Tax_Rate := 0.0;
         end if;

         -- Calculate tax rate.
         Tax := Tax_Rate * gross_pay - 25.0 * Float(dependents - 1);

         -- Tax shouldn't be negative. The IRS wouldn't like that.
         if Tax < 0.0 then
            Tax := 0.0;
         end if;

         -- Single return value.
         return Tax;
      end Compute_Tax;

      -- Computes the Fee that the Employee needs to pay.
      function Compute_Fee(gross_pay : Float; fee_code : Character) return Float is
         -- Local variable to hold the fee so a single return can be used.
         Fee : Float;
      begin
         -- Checks the code from the payroll file and calculates what the fee should be if needed.
         case fee_code is
            when 'A' => Fee :=  5.00;
            when 'B' => Fee := 10.00;
            when 'C' => Fee := 25.00;
            when 'D' => Fee := gross_pay * 0.02;
            when 'E' => Fee := gross_pay * 0.035;
            when 'F' => Fee := gross_pay * 0.05;
            when 'Z' => Fee := 0.0;
            when others => Fee := 10.0;
         end case;

         -- return calculated fee rounded to nearest integer.
         return Float'Rounding(Fee);
      end Compute_Fee;

      -- Calculate the net pay. Probably completely unnecessary to be its own subroutine, but all
      -- the other calculations are.
      function Compute_Net_Pay (gross_pay : Float; tax : Float; fee : Float) return Float is
      begin
         return (gross_pay - fee - tax);
      end Compute_Net_pay;

      -- Used to create correctly padded lines for the output files.
      procedure Write_Line (outFile : File_Type; field_name : String; value : Float) is
         -- Local string to store the line that will be printed.
         Str : String(1..18);
      begin
         -- pads the input to be the length of Str before printing to file.
         Move(" " & field_name & ": ", Str);

         -- prints Str, then a dollar sign, then the money value properly formatted.
         Put(outFile, Str);
         Put(outFile, "$");
         Put(outFile, value, 4, 2, 0);

         -- without this everything would be printed on the same line.
         New_Line(outFile, 1);
      end Write_Line;

      -- Used to create correctly padded output for the Total_Employees output for summary, because
      -- Write_Line can't take integers.
      procedure Write_Total_Employees (outFile : File_Type; field_name : String; value : Integer) is
         Str : String(1..18);
      begin
         -- Functions the same as Write_Line but in a way tailored towards integer output
         Move(" " & field_name & ": ", Str);
         Put(outFile, Str);
         Put(outFile, value, 5);

         New_Line(outFile, 1);
      end Write_Total_Employees;

      -- Function that uses Write_Line to just write the Payroll file.
      procedure Write_Payroll_File (outFile : File_Type; payroll : Payroll_Record) is
      begin
         -- "Pay for <name> is"
         -- "  Gross pay:       $<number>"
         -- "  Taxes:           $<number>"
         -- "  Fees:            $<number>"
         -- "  Net pay:         $<number>"
         -- 
         Put_Line(outFile, "Pay for " & Trim(payroll.Name, Both) & " is" );
         Write_Line(outFile, "Gross pay", payroll.Gross_Pay);
         Write_Line(outFile, "Taxes", payroll.Tax);
         Write_Line(outFile, "Fees", payroll.Fee);
         Write_Line(outFile, "Net pay", payroll.Net_Pay);
         New_Line(outFile, 1);

      end Write_Payroll_File;

      -- Writes the output to the summary file.
      procedure Write_Summary_File (outFile : File_TYPE; running_total : Summary_Record) is
      begin
         -- "SUMMARY"
         -- " Total Gross Pay: $<amount>"
         -- " Taxes:           $<amount>"
         -- " Fees:            $<amount>"
         -- " Net pay:         $<amount>"
         -- " Total Employees:  <amount>"
         -- " Avg Gross Pay:   $<amount>"
         -- " Avg Net Pay:     $<amount>"
         -- 
         Put_Line(outFile, "SUMMARY");
         Write_Line(outFile, "Total Gross Pay", running_total.Gross_Pay);
         Write_Line(outFile, "Taxes", running_total.Tax);
         Write_Line(outFile, "Fees", running_total.Fee);
         Write_Line(outFile, "Net pay", running_total.Net_Pay);
         Write_Total_Employees(outFile, "Total Employees", running_total.Num_Transactions);
         Write_Line(outFile, "Avg Gross Pay",
                    (running_total.Gross_Pay / Float(running_total.Num_Transactions)));
         Write_Line(outFile, "Avg Net Pay",
                    (running_total.Net_Pay / Float(running_total.Num_Transactions)));

         New_Line(outFile, 1);
      end Write_Summary_File;
   begin
      -- open the already existing input file, and creates the output file.
      Open(inFile, In_File, inPath);
      Create(payroll_file, Out_File, payroll_Path);

      -- Initializing the running total to 0. I'm unsure if this is strictly necessary, but it's
      -- safer this way.
      Running_Total := (
        Gross_Pay        => 0.0,
        Tax              => 0.0,
        Fee              => 0.0,
        Net_Pay          => 0.0,
        Num_Transactions => 0
      );

      -- debugging purposes.
      if Verbose then
         New_Line(2);
         Put_Line("Processing Transactions");
         New_Line(1);
      end if;

      -- loop until the file has been completely read.
      while not End_Of_File(inFile) loop
         -- Reads in the employee ID associated with the transaction. Using Move because it autopads
         -- the string to prevent "length check" error.
         Move(Get_Line(inFile),Transaction.ID);

         -- Reads in the hours the employee worked. Skip_Line is required because Get doesn't read
         -- the full line, and the next Get will error otherwise. There's probably a better way to
         -- do this.
         Get(inFile,Transaction.Hours);
         Skip_Line(inFile);

         -- Reads in the character that represents the Fee. The Skip_Line function is required for
         -- identical reasons as above, but, if EOF, it will error so that check is required.
         Get(inFile,Transaction.Fee);
         if not End_Of_File(inFile) then
            Skip_Line(inFile);
         end if;

         -- If the Transaction ID is valid then Index will be the Index in arr where the employee
         -- with that ID can be found. Otherwise, Index is -1.
         Index := Return_Employee_Index_If_Exists(arr, count, Transaction.ID);
         if Index > 0 then
            -- local Variable copies that index 
            Employee := arr(Index);

            -- Assign Payroll based on the needed Transaction and Employee fields. All the payroll
            -- computations are done in their own functions above.
            Payroll.Name := Employee.Name;
            Payroll.Gross_Pay := Compute_Gross_Pay(Transaction.Hours, Employee.Wages);
            Payroll.Tax := Compute_Tax(Payroll.Gross_Pay, Employee.Dependents);
            Payroll.Fee := Compute_Fee(Payroll.Gross_Pay, Transaction.Fee);
            Payroll.Net_Pay := Compute_Net_Pay(Payroll.Gross_Pay, Payroll.Tax, Payroll.Fee);

            -- Uses a case statement to determine if it needs to print the Error about an incorrect
            -- Fee code.
            case Transaction.Fee is
               -- If code is valid, do nothing. Otherwise, print Error.
               when 'A'..'F' | 'Z' => NULL;
               when others => Put_Line(payroll_file, "ERROR: Illegal Fee Code: " & Transaction.Fee);
            end case;

            -- Write the rest of the current payroll record to the Payroll file.
            Write_Payroll_File(payroll_file, payroll);

            -- Updates the running total, of all the specific monetary fields and also the number
            -- of valid transactions processed.
            Running_Total := (
              Gross_Pay        => Running_Total.Gross_Pay + Payroll.Gross_Pay, 
              Tax              => Running_Total.Tax + Payroll.Tax, 
              Fee              => Running_Total.Fee + Payroll.Fee, 
              Net_Pay          => Running_Total.Net_Pay + Payroll.Net_Pay, 
              Num_Transactions => Running_Total.Num_Transactions + 1 
            );

            

         -- If the ID is invalid, print an error about the ID not being found to the payroll file.
         else
            Put_Line(payroll_file, "ERROR: Employee ID " & Trim(Transaction.ID, Both) & " not found.");
            New_Line(payroll_file, 1);
         end if;

         -- for debugging purposes. Prints out the fields of the Transaction record.
         if Verbose then
            Put_Line(Transaction.ID);

            Put(Transaction.Hours, 0);
            New_Line(1);

            Put(Transaction.Fee);
            New_Line(1);
         end if;
         -- I stopped with the debugging blocks pretty early into the program. It was a bad model.
         -- It does make me what good ways to do debugging information are though.
      end loop;

      -- closes both of the files
      Close(inFile);
      Close(payroll_file);

      -- Creates the summary file, writes to it, and closes it.
      Create(summary_file, Out_File, summary_Path);
      Write_Summary_File(summary_file, Running_Total);
      Close(summary_file);
      
      
   end Process_Transactions_and_Output_To_Files;

-- I'm not sure if this is actually best practice, but it feels like the main function/upper most
-- level procedure should be a container for other, more specific procedure calls. The structure of
-- this program enforces that rule and, also, defines simple "helper" subprocedures within the ones
-- they are relevant to.
begin
   -- Takes in the input file, its path, the employees array, and the variable to increment as the
   -- employees input file is processed. After executing this subroutine, the Employees array should
   -- be populated.
   Populate_Employees(In_Employees, In_Employees_Path,
                      Employees, Num_Employees);

   -- This function processes transactions and outputs to files. It takes the transactions file,
   -- its path, the employee payroll out file, the summary file, and the array of employee records
   -- and its length.
   Process_Transactions_and_Output_To_Files(In_Payroll, In_Payroll_Path,
                                            Out_EmployeePay, Out_EmployeePay_Path,
                                            Out_Summary, Out_Summary_Path,
                                            Employees, Num_Employees);
   -- I think this procedure does too much and, if I were to work more on this, I'd probably rework
   -- it. I think that processing the transactions would be a good scope for this procedure, then
   -- another procedure to write to the payroll file, and another to write to the summary file.

end Program;










------------------
-- Output files --
------------------

-- employee_pay.txt
-- 
-- Pay for Roy_Estrada is
--  Gross pay:       $ 665.00
--  Taxes:           $ 179.55
--  Fees:            $  10.00
--  Net pay:         $ 475.45
-- 
-- Pay for Frank_Zappa is
--  Gross pay:       $ 472.50
--  Taxes:           $   0.00
--  Fees:            $  25.00
--  Net pay:         $ 447.50
-- 
-- Pay for Todd_Rundgren is
--  Gross pay:       $ 584.00
--  Taxes:           $  91.80
--  Fees:            $  10.00
--  Net pay:         $ 482.20
-- 
-- ERROR: Employee ID 130913 not found.
-- 
-- Pay for Steve_Hackett is
--  Gross pay:       $1039.51
--  Taxes:           $ 288.83
--  Fees:            $  52.00
--  Net pay:         $ 698.68
-- 
-- Pay for Ann_Wilson is
--  Gross pay:       $ 618.75
--  Taxes:           $ 142.31
--  Fees:            $  25.00
--  Net pay:         $ 451.44
-- 
-- Pay for Lainey_Schooltree is
--  Gross pay:       $ 270.00
--  Taxes:           $  46.60
--  Fees:            $   0.00
--  Net pay:         $ 223.40
-- 
-- Pay for Jimmy_Carl_Black is
--  Gross pay:       $ 300.00
--  Taxes:           $   0.00
--  Fees:            $  11.00
--  Net pay:         $ 289.00
-- 
-- ERROR: Employee ID 122212 not found.
-- 
-- Pay for Frank_Zappa is
--  Gross pay:       $ 580.50
--  Taxes:           $  41.10
--  Fees:            $  12.00
--  Net pay:         $ 527.40
-- 
-- Pay for Chester_Thompson is
--  Gross pay:       $ 145.80
--  Taxes:           $   0.00
--  Fees:            $   0.00
--  Net pay:         $ 145.80
-- 
-- Pay for Ann_Wilson is
--  Gross pay:       $ 568.13
--  Taxes:           $ 113.63
--  Fees:            $   5.00
--  Net pay:         $ 449.50
-- 
-- Pay for Ruth_Underwood is
--  Gross pay:       $ 522.00
--  Taxes:           $  68.96
--  Fees:            $  10.00
--  Net pay:         $ 443.04
-- 
-- Pay for Frank_Zappa is
--  Gross pay:       $ 162.00
--  Taxes:           $   0.00
--  Fees:            $   0.00
--  Net pay:         $ 162.00
-- 
-- ERROR: Illegal Fee Code: G
-- Pay for George_Duke is
--  Gross pay:       $ 620.92
--  Taxes:           $  92.81
--  Fees:            $  10.00
--  Net pay:         $ 518.11
-- 
-- Pay for Terry_Bozzio is
--  Gross pay:       $ 456.00
--  Taxes:           $  84.28
--  Fees:            $  16.00
--  Net pay:         $ 355.72
-- 
-- Pay for Todd_Rundgren is
--  Gross pay:       $ 839.50
--  Taxes:           $ 226.85
--  Fees:            $  42.00
--  Net pay:         $ 570.65
-- 
-- Pay for Nancy_Wilson is
--  Gross pay:       $ 590.20
--  Taxes:           $  93.04
--  Fees:            $   5.00
--  Net pay:         $ 492.16
-- 
-- Pay for Mike_Keneally is
--  Gross pay:       $ 483.75
--  Taxes:           $  62.89
--  Fees:            $  10.00
--  Net pay:         $ 410.86
-- 

-- summary.txt
-- 
-- SUMMARY
--  Total Gross Pay: $8918.55
--  Taxes:           $1532.64
--  Fees:            $ 243.00
--  Net pay:         $7142.91
--  Total Employees:    17
--  Avg Gross Pay:   $ 524.62
--  Avg Net Pay:     $ 420.17
-- 










------------
-- Report --
------------

--  Language Used: Ada.

-- 1. I implemented all of the program. It seemed like a relatively straightforward program.
--    The main challenge I had was tied to strings having to be exact lengths. It seemed like with
--    GNAT, it didn't matter how I defined them, they would always have to be exact length. After I
--    found the Move function it got easier though, because it will assign a string with the right
--    amount of whitespace to avoid "length check" errors. It also feels like a throwback to COBOL.
--
--    One issue that I ran into that was probably unique to me was related to differences between
--    Windows and Linux. txt files created in Windows use '\r\n' to signify the end of line in a
--    file, in Linux it's just '\n'. When reading in lines from files and then printing them out
--    late, the output would always have an additional space looking character after variables and I
--    couldn't figure out what the problem was. It was only when I remembered that pecularity that I
--    tried running `dos2unix` on the input files (which just changes the line endings) that the
--    extra characters went away. I am very suprised that GNAT doesn't just handle both by default,
--    I've known about that difference and all programming languages I've used have just handled it
--    (even COBOL). 

-- 2. It wasn't very hard. The main annoyance was having to look at language specs to figure out
--    what functions there were and how they worked. Ada doesn't seem like a popular enough language
--    to have an abundance of educational resources or people asking/answering questions about it on
--    StackOverflow.
--
--    The whole program probably took me 10-12 hours. The main issues I ran into were dealing with
--    strings, and figuring out the Windows/Linux issues. One thing I worried about that didn't
--    end up being much of an issue was getting a compiler working.

-- 3. The Strings! The fix length strings made it difficult. It took awhile to learn to work with
--    them. I also feel like the procedure definitions were very clunky and verbose. I tried to do
--    most things in subroutines but defining them was cumbersome and is probably less readable than
--    just having a massive function (which I still ended up having).
--
--    It feels like Ada is pretty cumbersome. It feels like trying to actually format strings is a
--    nightmare. It seems like you can give a width to Integers and Floats, but not Strings which
--    led to me feeling like the way I did file output formatting was very hacky.
--
--    I also probably made it harder on myself, because I think accessing variables that aren't
--    locally defined or explicit parameters is bad practice so I didn't use that feature of Ada
--    (or at the very least tried not to).

-- 4. I liked the access keywords in parameter passing. I like how intentional `out` is as a return
--    type. Outside of that, I am unsure. I didn't feel like any parts of the language got in my
--    way really, but there was nothing that I really recognized as being better about the way that
--    Ada does things. I don't think it would be hard to write other programs in Ada though.

-- 5. Easy string formatting utilities. Untyped parameter passing. Being able to iterate over an
--    array without having to think about the length of it. Case statements that can handle floats.

-- 6. I think it would mainly be the ones I mentioned in 5. I think those were the main things that
--    were missing.

-- 7. I think it would be easier to implement in languages with good string manipulation tools, like
--    Java and Python, I don't think it would be much easier in C. In C it would be less cumbersome
--    though because of the syntax.

-- 8. I actually know someone who really likes Ada, so if they soapbox hard enough, then, maybe. I
--    think I'd be more likely to use Ada than Pascal, so I'm glad I chose it. I don't think I'm
--    parcticular interest in that family of language though, there aren't necessarily any strong
--    benefits that I've noticed to using Ada from this assignment.

-- 9. I don't think so. I think using Ada has made me glad that Pascal lost out to C and that its
--    syntax won out. I think it's sort of interesting that in modern languages functions and
--    procedures are declared in the same way but functions have a void return type. It makes me
--    wonder if there's any benefit to them having different syntax because it would make people
--    aware they're actually pretty different things.


