# Program:  Program 4
#
# Language: Crystal. It's similar to Ruby syntactically and claims to be purely OO. The main difference
#                    Is that it's compiled.
#
# Description: A Very Simple adventure game implemented in an OOP style.


# Creature class. It's an abstract class because there's no reason to ever instantiate it.
# 
# Data:
#       hp - characters hit points
#   weapon - weapon that character is holding
#    armor - armor that character is wearing
#     type - the type of creature it is. 
#
# Methods:
#   initialize - constructor
#        fight - creature will fight with another creature until either have 0 hp
#      isAlive - returns false if hp <= 0
#  takesDamage - subtracts an amount from hp that's supplied from the method.
#        heals - adds an amount to hp that's supplied to the method.
abstract class Creature
  # define instance variables and give them getters. Defining instance variables seems option in
  # Crystal (unless you're using macros to setup getters/setters/both). It's much more clear to
  # explicitly define them.
  getter type : String
  getter weapon : Weapon
  getter armor : Armor
  getter hp : Int32

  # constructor for the class. Crystal programs will error and fail to compile if instance variables
  # aren't initialized, so this initializes them. 
  def initialize(type = "", hp = 0, weapon = Weapon.new, armor = Armor.new)
    @type = type
    @hp = hp
    @weapon = weapon
    @armor = armor
  end

  # this allows you to select an entry from a lookup_table that contains item information. Each
  # subclass has its own lookup table for item information, so none is defined here.
  def selectType(index : Int32)
    return @@LOOKUP_TABLE[index]
  end

  # selects a random item from the lookup_table. Used to generate NPCs with different items as well
  # as the player. If I were to expand this program, I think it would cool to have a limited selection
  # of all the items that are "starting gear" that will be initalized on the player, and have some
  # sort of scaling function that slowly introduced better gear.
  def selectRandomType
    selectType(rand(0 .. (@@LOOKUP_TABLE.size-1)))
  end

  # this class is where the fighting happens. It takes in the creature being fought, calculates the
  # amount of damage the enemy should take, applies that damage, does output, then allows the enemy
  # to attack back. This continues until either the player or the enemy is dead.
  def fight(c : Creature)
    while isAlive && c.isAlive
      i = 0
      while i < @weapon.numAttacks && c.isAlive
        damage = @weapon.calculateDamage(c.armor)
        if damage > 0
          c.takesDamage(damage)
          puts "#{@type} strikes with #{@weapon.type} and does #{damage} damage."
        else
          puts "#{@type} strikes with #{@weapon.type}, but #{c.type} is unfazed."
        end

        i += 1
      end

      if c.isAlive
        c.fight(self)
      else
        puts "#{c.type} is dead."

        # This section checks to see if your and your opponents weapons/armor are removable and, if so,
        # it gives you the option to switch weapons/armor with them. It gives you a prompt with all
        # the relevant info so you can make an informed decision (though, as of current, the goal is
        # to just get a mace)
        if @weapon.isRemovable && c.weapon.isRemovable && @weapon.type != c.weapon.type
          puts "\nThe #{c.type} was holding a #{c.weapon.type}:\n"
          @weapon.compareTo(c.weapon)
          print "Replace? (y/N) "

          if (gets == "y")
            @weapon = c.weapon
          end
        end

        if @armor.isRemovable && c.armor.isRemovable && @armor.type != c.armor.type
          puts "\nThe #{c.type} was wearing #{c.armor.type}:\n"
          @armor.compareTo(c.armor)
          print "Replace? (y/N) "

          if (gets == "y")
            @armor = c.armor
          end
        end

      end
    end
  end

  # used to check if creature has more than 0 hp/is alive.
  def isAlive
    if @hp > 0
      return true
    end

    return false
  end

  # subtracts the damage from the creature's health.
  def takesDamage(damage : Int32)
    @hp -= damage
  end

  # adds the amount to the creatures health. I could've defined takesDamage/heals in terms of the other
  # but this is a later addition, so I've gotten less elegant with my coding.
  def heals(amount : Int32)
    @hp += amount
  end
end

# User class. Inherits from Creature, but has an array of items and different constructor. The User
# has more health than other creatures, and is of type "User".
class User < Creature
  getter items : Array(Loot)

  # used to make sure the user is never carrying more than they should.
  @maxItems = 10

  # user begins with no items and 100hp
  def initialize
    super(type = "User", hp = 100)
    @items = [] of Loot
  end

  # method that will either pick up an item and return true or not have space and return false. I
  # probably should've implemented this as two methods like "canCarryMoreItems" and "pickUpItem". The
  # approach of "do thing and return true or return false" seems more complex/harder to reason about.
  def pickupItemIfRoom(item : Loot)
    if @items.size < @maxItems
      items << item
      return true
    else
      return false
    end
  end
end

# Mobile entity/NPC. Instead of having different subclasses for aggressive/passive, I have added a
# flag.
class Mob < Creature
  getter isAggressive : Bool

  # Just a lookup table of the different Mobs. You could add more and also add more attributes to them
  # that makes them genuinely different encounters.
  @@LOOKUP_TABLE = [
    {
      type: "Orc",
      isAggressive: false
    },
    {
      type: "Elf",
      isAggressive: true
    },
    {
      type: "Martian",
      isAggressive: true
    },
    {
      type: "Hunter",
      isAggressive: true
    },
  ]

  # constructor. If you don't enter a type, then the lookup_table will be used to randomly assign
  # attributes. You can enter type, hp, and aggression status if you want though. 
  #
  # one major annoyance of Crystal is if you attempt to use a subroutine to define data members, the
  # compiler will throw an error about those members not being directly instantiated. 
  def initialize(@type = "", @hp = rand(5..25), @isAggressive = true)
    if @type == ""
      entry = selectRandomType

      @type = entry[:type]
      @isAggressive = entry[:isAggressive]
    end

    # calls the parent constructor. The parent constructor also instantiates weapon/armor objects so
    # this call is required.
    super(@type, @hp)
  end
end


# abstract parent class for all the items.
abstract class Item
  getter type : String

  # constructor. I don't think anything uses this one, but I have to have it defined because Crystal
  # will throw an error because MY ABSTRACT CLASS has not instantiated the @type datum.
  def initialize(type = "")
    @type = type
  end

  # does the same thing as the Creature.selectRandomItem
  def selectItem(index : Int32)
    return @@LOOKUP_TABLE[index]
  end

  # does the same thing as the Creature.selectRandomType
  def selectRandomItem
    selectItem(rand(0 .. (@@LOOKUP_TABLE.size-1)))
  end
end

# Armor subclass. Originally I was going to create a subclass of Item called Equippable for Weapons
# and Armor. The reason for that is because they both share the field "isRemovable". I decided that's
# probably not enough of a reason to create an intermediary class. It seems very easy to overengineer
# inheritance relations.
class Armor < Item
  # getters/declarations for the Armor class data members.
  #   - protection is the amount of damage mitigated
  #   - isRemovable is if you can take the armor off
  getter protection : Int32
  getter isRemovable : Bool

  # lookup_table that contains the armor options. Amusingly, I had the protections on the armor a little
  # overtuned, so, early on, if anyone had a dagger and the enemy had a chainmail the person with the
  # dagger would have no chance of doing any damage.
  @@LOOKUP_TABLE = [
    {
      type: "ragged tunic",
      protection: 1,
      isRemovable: true
    },
    {
      type: "leather armor",
      protection: 2,
      isRemovable: true
    },
    {
      type: "chainmail",
      protection: 3,
      isRemovable: true
    },
  ]

  # constructor. selectRandomItem returns a named tuple from the lookup_table then uses that to assign
  # properties to the weapon object.
  def initialize
    entry = selectRandomItem
    @type = entry[:type]
    @protection = entry[:protection]
    @isRemovable = entry[:isRemovable]
  end

  # prints out a comparison to be used to decide if you want to switch weapons with your foe.
  def compareTo(a : Armor)
    puts "Type: #{@type} → #{a.type}",
         "Protection: #{@protection} → #{a.protection}",
         ""
  end
end

# weapon class. 
class Weapon < Item
  # getters
  #   - numAttacks is the number of swings a weapon gets each turn
  #   - maxDamagePerAttack is the highest damage number each attack can have
  #   - isRemovable is if the weapon can be replaced with another weapon
  getter numAttacks : Int32
  getter maxDamagePerAttack : Int32
  getter isRemovable : Bool

  # same old structure, slightly different fields. Given how few differentiating factors, the most
  # important factor with weapon is probably just total potential damage (so the mace).
  @@LOOKUP_TABLE = [
    {
      type: "dagger",
      maxDamagePerAttack: 5,
      numAttacks: 4,
      isRemovable: true
    },
    {
      type: "sword",
      maxDamagePerAttack: 20,
      numAttacks: 1,
      isRemovable: true
    },
    {
      type: "spear",
      maxDamagePerAttack: 12,
      numAttacks: 3,
      isRemovable: true
    },
    {
      type: "mace",
      maxDamagePerAttack: 35,
      numAttacks: 1,
      isRemovable: true
    },
    {
      type: "claws",
      maxDamagePerAttack: 15,
      numAttacks: 5,
      isRemovable: false
    }
  ]

  # constructor. works the same as the armor one but different fields.
  def initialize
    entry = selectRandomItem
    @type = entry[:type]
    @maxDamagePerAttack = entry[:maxDamagePerAttack]
    @numAttacks = entry[:numAttacks]
    @isRemovable = entry[:isRemovable]
  end

  # calculates the damage of a hit. It can be from 1 to the maximum damage per hit of the weapon.
  def calculateDamage(a : Armor)
    return rand(1..@maxDamagePerAttack) - a.protection
  end

  # calculates the max damage per turn for a weapon. I originally had compareTo using this value, but
  # switched to it always prompting you to switch weapons if you want. 
  def calculateMaxDamage
    return @maxDamagePerAttack * @numAttacks
  end

  # same as the Armor.compareTo but it displays all the important Weapon fields.
  def compareTo(w : Weapon)
    puts "Type: #{@type} → #{w.type}",
         "Max Attack Damage: #{@maxDamagePerAttack} → #{w.maxDamagePerAttack}",
         "Number of Attacks: #{@numAttacks} → #{w.numAttacks}",
         ""
  end
end

# this is subclass of item, but a parent class of both Treasure and Food. The reason I made this class
# is because the User class picks up Treasure and Food items. If I made the Array that holds them items
# of type Item, then it could hold Weapons and Armor (which would unintentional). By defining this
# subclass, I can make that Array only hold Loot objects.
abstract class Loot < Item
end

# Treasure class. Inherits from Loot which inherits from Item.
class Treasure < Loot
  getter value : Int32

  # same pattern, this time with jokes though.
  @@LOOKUP_TABLE = [
    {
      type: "Priceless Artifact",
      value: 1,
    },
    {
      type: "Worthless Rubbish",
      value: 50,
    },
  ]

  def initialize
    entry = selectRandomItem
    @type = entry[:type]
    @value = entry[:value]
  end
end

# Food class.
class Food < Loot
  # maxHeal is the max amount that the food item will heal you (min is 1).
  getter maxHeal : Int32

  @@LOOKUP_TABLE = [
    {
      type: "Rotten Flesh",
      maxHeal: 3,
    },
    {
      type: "Cookie",
      maxHeal: 10,
    },
    {
      type: "Delicious Steak",
      maxHeal: 75,
    },
    {
      type: "Ultra Shroom",
      maxHeal: 150,
    },
  ]

  def initialize
    entry = selectRandomItem

    @type = entry[:type]
    @maxHeal = entry[:maxHeal]
  end

  # small little function that just returns the random number. 
  def calculateHeal
    return rand(1..@maxHeal)
  end
end





# The Room class potentially contains loot, an npc, and 1 or 2 exits to other rooms. Instead of
# implementing subclasses I just implemented room types. There are "start", "normal", and "exit"
# rooms.
class Room
  # generates getter and setter for exits. I use the setter in Game to build a room structure.
  property exits : Array(Room)

  # type - type of room
  # npc - a potential non-playable character in the room. Can be non-aggressive.
  # loot - potential treasure and food in the room. Can be between 0 and 4 items.
  getter type : String
  getter npc : Mob
  getter loot : Array(Loot)

  # constructor. By default the npc in the room is a Mob of type "null". The reason for this (instead
  # of just leaving the npc initalized) is that Crystal will throw a compile error if a data member
  # is uninitalized. It feels bad to have to create a new object with a "null" string just to sate
  # the compiler.
  def initialize(@type = "normal", @npc = Mob.new("null"))
    @loot = [] of Loot
    @exits = [] of Room

    # if the room is a normal room, generate the room content
    if @type == "normal"
      generateRoomContent
    end
  end

  # add mob (0-1) and items (0-4) to the room
  def generateRoomContent
    maybeAddMob
    maybeAddItems
  end

  # n% of the time, this will return true.
  def percentChance(n)
    return rand(0 .. 100) > 100 - n
  end

  # 80% of the time add a mob to the room.
  def maybeAddMob(n = 80)
    if percentChance(n)
      @npc = Mob.new
    end
  end

  # maybe add items to the room. With default n, the first item has an 80% chance, second 60%, third
  # is 40%, 4th is 20%, and 5th is 0%.
  def maybeAddItems(n = 80)
    while percentChance(n)
      @loot << returnFoodOrTreasure
      n -= 20
    end
  end

  # 50% of the time add treasure, otherwise add food to the room.
  def returnFoodOrTreasure
      if rand(1..2) == 1
        return Treasure.new
      else
        return Food.new
      end
  end
end

# this is the game loop class. It contains the logic to define a default room layout, a user object,
# Room objects and a pointer to the current one. On top of that it has the menu and most of the status
# messages for the player. 
class Game
  # currentRoom - room the user is currently in
  # user - the player
  getter currentRoom : Room
  getter user : User

  # constructor. Initalizes a user, and creates the starting room. Then calls the function
  # generateRoomStructure. I have a room layout hardcoded in that method.
  def initialize
    @user = User.new
    @currentRoom = Room.new("start")

    generateRoomStructure
  end

  # main loop. essentially just keeps calling the displayCurrentRoom function until the user either
  # dies or reaches the exit.
  def main
    while @user.isAlive && @currentRoom.type != "exit"
      displayCurrentRoom
    end

    # If you died you get a specific message about it.
    if !@user.isAlive
      puts "\n\nYou have died!"
    end
  end

  # I was considering writing a function to generate room layouts on the fly, but it added some
  # complexity i didn't really want to deal with this time. one thing that i didn't want to deal with
  # was being able to go to previous rooms which is why every room without any exits are the exit here.
  def generateRoomStructure
    ###########################################
    #                Entrance                 #
    #               /        \                #
    #             [0]       [1]               #
    #              |         |                #
    #            [0,0]     [1,0]              #
    #              |       /  \               #
    #            exit   exit  exit            #
    ###########################################

    # Crystal uses << to append to arrays. It's probably like that in Ruby.
    @currentRoom.exits << Room.new << Room.new
    @currentRoom.exits[0].exits << Room.new
    @currentRoom.exits[0].exits[0].exits << Room.new("exit")

    @currentRoom.exits[1].exits << Room.new
    @currentRoom.exits[1].exits[0].exits << Room.new("exit") << Room.new("exit")
  end

  # This is a chunky function that displays
  def displayCurrentRoom
    if @currentRoom.type == "start"
      puts "You're in the starting room of the dungeon."
    end

    # just a few messagesa about the state of yourself and the room itself
    displayHP
    displayExits
    displayItems
    displayNPC

    # When calling displayNPC, it will trigger a fight if there's an aggressive NPC in the room, so
    # that's why I check if the user is alive here.
    if !@user.isAlive
      return
    end

    # After that the the menu comes up for you to interact in the room.
    displayMenu
    processMenuInput
    
    if @currentRoom.type == "exit"
      puts "The sunlight blinds you. You're finally free of this hell."
    end
  end

  def displayHP
    puts "You currently have #{@user.hp} health."
  end

  # A helper function that returns true if there are two exits. It's probably more verbose than just
  # inlining it in the 2 places I use it, but I like how much more explicit it is.
  def isMultipleExits
    return @currentRoom.exits.size > 1
  end

  # Tells you how many exits there are to your current room.
  def displayExits
    if isMultipleExits
      prompt = "There are two doors in front of you."
    else
      prompt = "There is a single door in front of you."
    end

    puts prompt
  end

  # loops through the items in the loot Array in the room displaying them on the screen.
  def displayItems
    i = 0
    while i < @currentRoom.loot.size
      puts "You see a #{@currentRoom.loot[i].type} in the room."
      i += 1
    end
  end

  # Displays messages if there's an NPC in the room with you. If there is and the NPC is aggressive,
  # you get into a fight.
  def displayNPC
    if @currentRoom.npc.type != "null"
      puts "There is a #{@currentRoom.npc.type} in the room with you!"

      if @currentRoom.npc.isAggressive
        puts "It's noticed you and is coming at you! (Press Enter)"
        gets

        @user.fight(@currentRoom.npc)
      else
        puts "Luckily, they seem passive. They may not stay that way if you take anything though."
      end
    end
  end

  # Displays a menu for interacting with things in the room.
  def displayMenu
    puts "\nWhat would you like to do:\n",
         "1 - Enter the next room.",
         "2 - Attack the creature in the room.",
         "3 - Take an item.",
         "4 - Drop an item.",
         "5 - Eat food.",
         "6 - Rest."
  end

  # Gets input and keeps you in a loop until you choose to "Enter the next room".
  def processMenuInput
    # you have assign a value before you use it, so i defined input to an invalid one.
    input = -1

    # a flag that prevents you from continuing to rest over and over in the same room
    alreadyRested = false

    while input != "1"

      input = gets

      # case statement that recognizes the numbers beside the options in the menu.
      case input
      when "1"
        chooseExit
      when "2"
        chooseAttack
      when "3"
        chooseTakeItem
      when "4"
        chooseDropItem
      when "5"
        chooseEatFood
      when "6"
        if ! alreadyRested
          alreadyRested = true
          chooseRest
        else
          puts "You've already rested in this room."
        end
      end

      # keep displaying the menu in the loop if you don't leave the current room.
      if input != "1"
        displayMenu
      end
    end

  end

  # exit the room. if there are two exits you get a choice between them.
  def chooseExit
    if isMultipleExits
      prompt = "There are two doors in front of you. Do you choose 'left' or 'right'? "

      print prompt
      input = gets
      puts ""

      # originally I was very meticulous about preventing IO errors from crashing the program. Here
      # is an example of that. If you don't give the two valid inputs, then you will be prompted
      # until you do. (Eventually I got lazy about doing that though.)
      while input != "left" && input != "right"
        puts "Invalid input! Try again."

        print prompt
        input = gets
        puts ""
      end

      # updates the currentRoom instance datum to the room you're entering. After a few steps we will
      # return to Game.main, and then displayRoom will be called again, but with the new currentRoom. 
      if input == "left"
        @currentRoom = @currentRoom.exits[0]
      else
        @currentRoom = @currentRoom.exits[1]
      end

      puts "You take the handle of the #{input}-most door and push.",
    else
      @currentRoom = @currentRoom.exits[0]
      puts "You take the handle of the door and push."
    end

    puts "The door is heavy, but manageable, and you enter the next room."
  end

  # If you choose to attack the passive NPC in the room. First it will check if there's a dead NPC
  # or no NPC in the room, and send a status message before returning. If there is actually a living
  # NPC then fight.
  def chooseAttack
    if @currentRoom.npc.type != "null" && @currentRoom.npc.isAlive
      @user.fight(@currentRoom.npc)
    else
      puts "You're alone in the room."
    end
  end

  # if you choose to take an item from the room. First checks if there's any items in the room. Then
  # asks you which item to pick up from the room. After that it adds the item to your inventory and
  # removes it from the room's item array.
  def chooseTakeItem
    if @currentRoom.loot.size == 0
      puts "There are no items in the room."
      return
    end

    puts "\nWhat would you like to pickup?\n"
    i = 0 
    while i < @currentRoom.loot.size
      puts "#{i} - #{@currentRoom.loot[i].type}"

      i += 1
    end

    index = gets


    # here index can be Nil, and if I don't check that it isn't before using it, then Crystal throws
    # a compilation error.
    if index
      item = @currentRoom.loot[index.chomp.to_i]
      @currentRoom.loot.delete_at(index.chomp.to_i)
    else
      puts "An error occured. Try again!"
    end


    # same as with index.
    if item
      # if pickupItemIfRoom fails then prompts the user to select an item to remove from their
      # inventory before trying to pick up an item again.
      if ! @user.pickupItemIfRoom(item)
        prompt = "\nYour inventory is full. Would you like to drop something? (y/N) "

        puts prompt
        input = gets
        puts ""

        while input != "y" && input != "n"
          puts "Invalid input!"

          puts prompt
          input = gets
          puts ""
        end

        if input == "y"
          chooseDropItem
          chooseTakeItem
        end
      end
    end
  end

  # gives you a menu to drop an item from your inventory. 
  def chooseDropItem
    if @user.items.size == 0
      puts "\nYou don't have any items in your inventory."
      return
    end

    # prints a list of your inventory and gets the index from you of the item you want to drop.
    puts "\nWhat would you like to drop?\n"
    i = 0 
    while i < @user.items.size
      puts "#{i} - #{@user.items[i].type}"

      i += 1
    end

    input = gets

    if input
      @user.items.delete_at(input.chomp.to_i)
    end
  end

  # gives you a prompt of the food items in your inventory to eat.
  def chooseEatFood
    # foodIndexes is an array of the Indexes of the food items in your inventory. It means only
    # having to parse the @user.items array once.
    foodIndexes = [] of Int32

    i = 0 
    while i < @user.items.size
      if @user.items[i].is_a?(Food)
        foodIndexes << i
      end
      i += 1
    end

    # All the items in your inventory aren't food or there are no items in your inventory.
    if foodIndexes.size == 0
      puts "No food in your inventory."
      return
    end

    puts "Select a food item to consume."

    # prints prompt to choose food item.
    i = 0 
    while i < foodIndexes.size
      puts "#{foodIndexes[i]} - #{@user.items[i].type}."

      i += 1
    end

    index = gets
    if index
      item = @user.items[index.chomp.to_i]

      # checking to see if the item was a food was literally required. Even though, I have logic that
      # selects out "Treasure" class items, Crystal will throw a compiler error here because Treasure
      # doesn't have a "maxHeal" datum. It's kind of frustrating.
      if item.is_a?(Food)
        healAmount = rand(1 .. item.maxHeal)
        @user.heals(healAmount)
        puts "User ate a #{item.type} healed #{healAmount} hp."

        @user.items.delete_at(index.chomp.to_i)
      else
        # top tier error checking.
        puts "some error occurred."
      end
      
    else
      puts "some error occurred."
    end
    
  end

  # If you choose to rest in the room it heals you up to 5hp and prints status messages. You can only
  # heal once per room.
  def chooseRest
    puts "You lay down on the hard stone floor, too wearied to really care, before drifting off to sleep"
    healAmount = rand(1..5)
    @user.heals(healAmount)
    puts "You regained #{healAmount} hp."
  end
end

while true
  game = Game.new
  game.main

  # Whether you died or won, you're asked if you want to play again. 
  print "Play again? (y/N) "
  input = gets
  puts ""

  if input != "y"
    exit
  end
end


############
## Output ##
############

# There are two doors in front of you. Do you choose 'left' or 'right'? left
# 
# You take the handle of the left-most door and push.
# The door is heavy, but manageable, and you enter the next room.
# You currently have 100 health.
# There is a single door in front of you.
# You see a Priceless Artifact in the room.
# There is a Martian in the room with you!
# It's noticed you and is coming at you! (Press Enter)
# 
# User strikes with sword and does 9 damage.
# Martian strikes with mace and does 6 damage.
# User strikes with sword and does 3 damage.
# Martian strikes with mace and does 17 damage.
# User strikes with sword, but Martian is unfazed.
# Martian strikes with mace and does 5 damage.
# User strikes with sword, but Martian is unfazed.
# Martian strikes with mace and does 31 damage.
# User strikes with sword and does 10 damage.
# Martian strikes with mace and does 33 damage.
# User strikes with sword and does 1 damage.
# Martian strikes with mace and does 7 damage.
# User strikes with sword and does 8 damage.
# Martian is dead.
# 
# The Martian was holding a mace:
# Type: sword → mace
# Max Attack Damage: 20 → 35
# Number of Attacks: 1 → 1
# 
# Replace? (y/N) y
# 
# What would you like to do:
# 1 - Enter the next room.
# 2 - Attack the creature in the room.
# 3 - Take an item.
# 4 - Drop an item.
# 5 - Eat food.
# 6 - Rest.
# 3
# 
# What would you like to pickup?
# 0 - Priceless Artifact
# 0
# 
# What would you like to do:
# 1 - Enter the next room.
# 2 - Attack the creature in the room.
# 3 - Take an item.
# 4 - Drop an item.
# 5 - Eat food.
# 6 - Rest.
# 6 
# You lay down on the hard stone floor, too wearied to really care, before drifting off to sleep
# You regained 1 hp.






############
## Report ##
############

# 1. I implemented all of it.

# 2. I can imagine it would be pretty difficult, because the classes are pretty tightly coupled. It
#    would likely be easier if you laid out the methods and what the structure of their inputs and
#    outputs are.

# 3. Crystal was pretty easy to use, there were certain things that made it more difficult to use
#    though. It seems like Crystal's compiler is relatively safe, so it throws errors if things are
#    not initialized and in situations where you may end up with a Nil value. I imagine it's probably
#    useful when you're familiar with Crystal, but it ended up being a little annoying getting errors
#    for things that didn't feel like they mattered to me when I just kind of wanted my program to
#    work.

# 4. Not very many. The documentation for it isn't that bad and most things are implemented in a way
#    that's familiar. One odd thing about Crystal though is it doesn't seem to have a for loop. 

# 5. To be honest, implementing it wasn't difficult at all really. I think that one thing that makes
#    writing code a lot easier is if you have it setup to autorecompile on changes so errors are
#    much easier to sort out.
#
#    I think that Crystal is a perfectly fine language to write OO programs in.

# 6. It seems like it has more guard rails in Java. I don't believe that Java forces you to initalize
#    all data members in a class in each constructor, or requires directly initalizing them in the/a
#    constructor. Nor does Java force you to check for null/nil values before using a variable that
#    could be null.
#
#    It probably would've been easier to write in Java because of the lack of those saftey mechanisms.

# 7. I would add more input checking because about halfway through I got lazy with that. I would also
#    write a function to generate a layout for my dungeon. Another thing is I would add different
#    properties to weapon and armor that would differentiate them further because, at the moment, it
#    is essentially just "bigger number = better."

# 8. I thought using Crystal was pretty fun. It kind of makes me wonder how different it is from Ruby.
#    I was going to use smalltalk but it seemed way too daunting to do that, so maybe Program 5?
