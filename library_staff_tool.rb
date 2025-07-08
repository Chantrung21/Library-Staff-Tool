require "gosu"     # Gosu library for graphics and windowing
require "rubygems" # RubyGems for gem management
require "date"     # Date library for date handling

# --- Constants ---
module ZOrder
  BACKGROUND, PLAYER, UI = *0..2   #Drawing order
end

module Status
  AVAILABLE, BORROWED = *0..1  
end

Book_status = ["Available", "Borrowed"]

# --- Data Models ---
# Book Record
class Book
  attr_accessor :id, :title, :author, :status, :borrowed_name, :borrowed_date
  def initialize(id, title, author, status, borrowed_name, borrowed_date)
    @id = id
    @title = title
    @author = author
    @status = status
    @borrowed_name = borrowed_name
    @borrowed_date = borrowed_date
  end
end
# Borrower Record
class Borrower
  attr_accessor :name, :borrowed_books
  def initialize(name)
    @name = name
    @borrowed_books = []
  end
end

# --- Main Application ---
class LibraryStaffTool < Gosu::Window
  def initialize
    super 800, 600
    self.caption = "Library Staff Tool"
    @menu_background_image = Gosu::Image.new("images/background.png")
    @book_list = []
    @message = ""
    @current_page = 0
    @fonts = {
      title: Gosu::Font.new(40, name: "Times New Roman"),
      menu: Gosu::Font.new(30, name: "Times New Roman"),
      instruction: Gosu::Font.new(25, name: "Times New Roman")
    }
    @menu_options = [
      "View All Books",
      "Borrow a Book",
      "Return a Book",
      "Add New Books",
      "Save / Load Data",
      "Exit"
    ]
    @colors = {
      title: Gosu::Color.argb(0xffeeeeee),
      menu_item: Gosu::Color.argb(0xffdddddd),
      highlight: Gosu::Color.argb(0xffffd700),
      instruction: Gosu::Color.argb(0xffeeeeee)
    }
    
@search_mode = false             # Flag to indicate if user is currently in search input mode
@search_input = ""               # Stores user input for searching books
@search_result = []              # Array of books matching the search input
@selected_index = 0              # Index for navigating menu selections
@current_screen = :main_menu     # Current screen/screen state (e.g., :main_menu, :view_books, etc.)
@search_page = 0                 # Current page in the search results (pagination)

@borrower_name = ""              # Name of the person borrowing books
@borrow_step = :enter_name       # Current step in the borrowing process (:enter_name, :select_books, etc.)
@borrow_count = 0                # Number of books to borrow
@borrowed_books = []             # List of books selected to borrow
@borrow_input = ""               # Text input during borrowing steps (ID or other info)
@borrow_index = 0                # Index used when selecting books to borrow

@return_input = ""               # Input for returning books (borrower's name or ID)
@return_step = :enter_name       # Current step in return process (:enter_name, :select_books, etc.)
@return_borrower = nil           # The borrower object currently returning books
@return_books = []               # Books borrowed by the borrower (to be returned)
@return_selected = []            # List of books selected to return
@return_message = ""             # Message to show on the return screen (e.g., success or error)

@add_books_step = :enter_count   # Current step in adding books (:enter_count, :enter_details, etc.)
@add_books_input = ""            # Input text for book count or book details
@add_books_total = 0             # Total number of books to be added
@add_books_index = 0             # Index of the current book being added
@add_books_list = []             # List to store all the new books before adding to library
@add_books_message = ""          # Message shown during book addition (e.g., confirmation or error)

  end

  # --- Drawing Methods ---
  def draw
    @menu_background_image.draw(0, 0, ZOrder::BACKGROUND)
    case @current_screen
    when :main_menu
      draw_main_menu
    when :save_load
      draw_save_load_menu
    when :view_books
      draw_view_books_screen
    when :search_screen
      draw_search_screen
    when :borrow_book
      draw_borrow_screen
    when :return_book
      draw_return_screen
    when :add_books
      draw_add_books_screen
    end
  end

  def draw_main_menu
    title = "Library Staff Tool"
    title_width = @fonts[:title].text_width(title)
    x = (width - title_width) / 2
    y = 100
    @fonts[:title].draw_text(title, x, y, 0, 1.0, 1.0, @colors[:title])

    index = 0
    while index < @menu_options.length
      option = @menu_options[index]
      y_position = 200 + index * 50
      Gosu.draw_rect(230, y_position - 5, 340, 40, Gosu::Color.argb(0xaa000000), ZOrder::BACKGROUND)
      number_text = "[#{index + 1}]"
      number_width = @fonts[:menu].text_width(number_text)
      @fonts[:menu].draw_text(number_text, 250, y_position, 0, 1.0, 1.0, @colors[:highlight])
      color = (index == @selected_index) ? @colors[:highlight] : @colors[:menu_item]
      @fonts[:menu].draw_text(option, 250 + number_width + 20, y_position, 0, 1.0, 1.0, color)
      index += 1
    end

    instruction = "Press 1-6 to select or ↑/↓ to navigate, ENTER to confirm"
    instruction_width = @fonts[:instruction].text_width(instruction)
    x = (width - instruction_width) / 2
    y = 500
    @fonts[:instruction].draw_text(instruction, x, y, 0, 1.0, 1.0, @colors[:instruction])
  end

  def draw_save_load_menu
     @menu_background_image.draw(0, 0, ZOrder::BACKGROUND)
    if @message != ""
      msg_width = @fonts[:instruction].text_width(@message)
      @fonts[:instruction].draw_text(@message, (width - msg_width) / 2, 400, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
    end
    title = "Save / Load Data"
    title_width = @fonts[:title].text_width(title)
    @fonts[:title].draw_text(title, (width - title_width) / 2, 80, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    options = [
      "[1] Save to File",
      "[2] Load from File",
      "[0] Back to Main Menu"
    ]
    y = 180
    i = 0
    while i < options.length
      @fonts[:menu].draw_text(options[i], 100, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
      y += 50
      i += 1
    end
  end

  def draw_view_books_screen
     @menu_background_image.draw(0, 0, ZOrder::BACKGROUND)
    header = "All Books in Library"
    w = @fonts[:title].text_width(header)
    @fonts[:title].draw_text(header, (width - w) / 2, 30, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    headers = ["ID", "Title", "Author", "Status", "Borrower", "Date"]
    x_pos = [30, 120, 300, 450, 550, 680]
    i = 0
    while i < headers.length
      @fonts[:menu].draw_text(headers[i], x_pos[i], 100, ZOrder::UI, 1.0, 1.0, Gosu::Color.new(255, 211, 211, 211))
      i += 1
    end

    books_per_page = 10
    start_index = @current_page * books_per_page
    end_index = [start_index + books_per_page, @book_list.size].min
    y = 140
    i = start_index
    while i < end_index
      book = @book_list[i]
      status_text = Book_status[book.status]
      borrower = book.borrowed_name.empty? ? "none" : book.borrowed_name
      borrowed_date = book.borrowed_date.empty? ? "none" : book.borrowed_date
      @fonts[:instruction].draw_text(book.id, x_pos[0], y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      @fonts[:instruction].draw_text(book.title, x_pos[1], y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      @fonts[:instruction].draw_text(book.author, x_pos[2], y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      @fonts[:instruction].draw_text(status_text, x_pos[3], y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      @fonts[:instruction].draw_text(borrower, x_pos[4], y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      @fonts[:instruction].draw_text(borrowed_date, x_pos[5], y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      y += 30
      i += 1
    end

    footer_msg = "[0] Main Menu [S] Search Book"
    footer_msg += "   [N] Next Page" if end_index < @book_list.size
    footer_msg += "   [P] Previous Page" if @current_page > 0
    msg_width = @fonts[:instruction].text_width(footer_msg)
    @fonts[:instruction].draw_text(footer_msg, (width - msg_width) / 2, height - 40, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  end

  def draw_search_screen
     @menu_background_image.draw(0, 0, ZOrder::BACKGROUND)
    title = "Search Books"
    w = @fonts[:title].text_width(title)
    @fonts[:title].draw_text(title, (width - w) / 2, 40, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    prompt = "Enter ID / Title / Author: #{@search_input}_"
    @fonts[:menu].draw_text(prompt, 80, 120, ZOrder::UI, 1.0, 1.0, Gosu::Color::CYAN)

    books_per_page = 10
    start_index = @search_page * books_per_page
    end_index = [start_index + books_per_page, @search_result.size].min

    if !@search_result.empty?
      @fonts[:instruction].draw_text("Results:", 80, 160, ZOrder::UI)
      i = start_index
      y = 190
      while i < end_index && y < height - 50
        book = @search_result[i]
        line = "#{book.id} - #{book.title} by #{book.author} (#{Book_status[book.status]})"
        @fonts[:instruction].draw_text(line, 90, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
        y += 25
        i += 1
      end
    elsif @search_input != ""
      msg = "No books found for '#{@search_input}'"
      @fonts[:instruction].draw_text(msg, 80, 180, ZOrder::UI, 1.0, 1.0, Gosu::Color::RED)
    end

    footer1 = "[ENTER] Search    [BACKSPACE] Delete    [N] Next Page"
    footer2 = "[P] Prev Page    [S] Search Again      [0] Back"
    footer1_width = @fonts[:instruction].text_width(footer1)
    footer2_width = @fonts[:instruction].text_width(footer2)
    x1 = (width - footer1_width) / 2
    x2 = (width - footer2_width) / 2
    @fonts[:instruction].draw_text(footer1, x1, height - 50, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
    @fonts[:instruction].draw_text(footer2, x2, height - 30, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  end

  def draw_borrow_screen
     @menu_background_image.draw(0, 0, ZOrder::BACKGROUND)
    y = 100
    case @borrow_step
    when :enter_name
      @fonts[:menu].draw_text("Enter borrower's name: #{@borrow_input}_", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    when :enter_count
      @fonts[:menu].draw_text("How many books to borrow? #{@borrow_input}_", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    when :enter_book_id
      book_num = @borrow_index + 1
      @fonts[:menu].draw_text("Enter Book ID ##{book_num}: #{@borrow_input}_", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    when :done
      @fonts[:menu].draw_text("Borrow successful!", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
      y += 50
      @fonts[:instruction].draw_text("Return within 14 days. Late return fine: 5RM/day", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
      y += 50
      @fonts[:instruction].draw_text("[0] Back to main menu", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
    when :error
      @fonts[:menu].draw_text(@message, 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::RED)
      y += 50
      @fonts[:instruction].draw_text("[C] Try another ID    [0] Return to main menu", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
    when :confirm_existing_name
      @fonts[:instruction].draw_text(@message, 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::RED)
      y += 50
      @fonts[:instruction].draw_text("[Y] Yes   [N] No", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
    when :has_outstanding_books
      @fonts[:instruction].draw_text(@message, 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::RED)
      y += 50
      @fonts[:instruction].draw_text("[0] Return to main menu", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
    when :enter_name_error, :error_name_error
      @fonts[:instruction].draw_text(@message, 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::RED)
      y += 50
      @fonts[:instruction].draw_text("[C] Try again    [0] Return to main menu", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
    when :error_books
      @fonts[:instruction].draw_text(@message, 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::RED)
      y += 50
      @fonts[:instruction].draw_text("[C] Try again    [0] Return to main menu", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
    end
  end

  def draw_return_screen
     @menu_background_image.draw(0, 0, ZOrder::BACKGROUND)
    y = 100
    case @return_step
    when :enter_name
      @fonts[:menu].draw_text("Enter borrower's name: #{@return_input}_", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    when :not_found
      @fonts[:menu].draw_text("No books found for this name.", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::RED)
      y += 40
      @fonts[:instruction].draw_text("[C] Try another name    [0] Main Menu", 80, y, ZOrder::UI)
    when :select_books
      @fonts[:menu].draw_text("Books borrowed by #{@return_borrower[:name]}:", 80, y, ZOrder::UI)
      y += 40
      i = 0
      today = Date.today
      while i < @return_books.size
        book = @return_books[i]
        borrowed_date = Date.parse(book.borrowed_date)
        days = (today - borrowed_date).to_i
        fine = [0, days - 14].max * 5
        line = "#{i + 1}. #{book.title} (Borrowed on #{book.borrowed_date}, #{days} days ago, Fine: RM#{fine})"
        @fonts[:instruction].draw_text(line, 100, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        y += 30
        i += 1
      end
      y += 30
      @fonts[:instruction].draw_text("Enter book number to return, [A] Return All, [0] Main Menu", 80, y, ZOrder::UI)
    when :confirm_return
      @fonts[:menu].draw_text(@return_message, 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
      y += 40
      @fonts[:instruction].draw_text("[Y] Yes   [N] No", 80, y, ZOrder::UI)
    when :done
      @fonts[:menu].draw_text("Books returned successfully.", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
      y += 40
      @fonts[:instruction].draw_text("[0] Back to Main Menu", 80, y, ZOrder::UI)
    end
  end

  def draw_add_books_screen
     @menu_background_image.draw(0, 0, ZOrder::BACKGROUND)
    y = 100
    case @add_books_step
    when :enter_count
      @fonts[:menu].draw_text("Enter number of books to add (1-10): #{@add_books_input}_", 80, y, ZOrder::UI)
    when :enter_id
      @fonts[:menu].draw_text("Enter Book ID for book ##{@add_books_index + 1}: #{@add_books_input}_", 80, y, ZOrder::UI)
    when :enter_title
      @fonts[:menu].draw_text("Enter Title for book ##{@add_books_index + 1}: #{@add_books_input}_", 80, y, ZOrder::UI)
    when :enter_author
      @fonts[:menu].draw_text("Enter Author for book ##{@add_books_index + 1}: #{@add_books_input}_", 80, y, ZOrder::UI)
    when :duplicate
      @fonts[:menu].draw_text("Book already exists or invalid Book ID (4 digits)", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::RED)
      y += 40
      @fonts[:instruction].draw_text("[C] Continue    [0] Main Menu", 80, y, ZOrder::UI)
    when :done
      @fonts[:menu].draw_text("Books added successfully!", 80, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
      y += 40
      @fonts[:instruction].draw_text("[0] Back to main menu", 80, y, ZOrder::UI)
    end
  end

  # --- Data Methods ---
  def load_books_from_file(filename)
    books = []
    file = File.open(filename, "r")
    count = file.gets.to_i
    i = 0
    while i < count
      line = file.gets.chomp
      id, title, author, status, name, date = line.split(",")
      books << Book.new(id, title, author, status.to_i, name, date)
      i += 1
    end
    file.close
    books
  end

  def save_books_to_file(filename, books)
    file = File.open(filename, "w")
    file.puts books.size
    i = 0
    while i < books.size
      book = books[i]
      file.puts [book.id, book.title, book.author, book.status, book.borrowed_name, book.borrowed_date].join(",")
      i += 1
    end
    file.close
  end

  def save_new_books_to_file(new_books)
    lines = []
    if File.exist?("books.txt")
      file = File.open("books.txt", "r")
      while line = file.gets
        lines << line.strip
      end
      file.close
    end
    current_count = 0
    old_books = []
    if lines.size > 0
      current_count = lines[0].to_i
      old_books = lines[1..-1]
    end
    i = 0
    while i < new_books.size
      book = new_books[i]
      old_books << "#{book.id},#{book.title},#{book.author},0,none,none"
      i += 1
    end
    file = File.open("books.txt", "w")
    file.puts (current_count + new_books.size).to_s
    i = 0
    while i < old_books.size
      file.puts old_books[i]
      i += 1
    end
    file.close
  end

  def save_borrower_record(filename, name, books)
    file = File.open(filename, "a")
    ids = books.map(&:id).join(";")
    file.puts "#{name},#{ids},#{Time.now.strftime("%Y-%m-%d")}"
    file.close
  end

  def reset_borrow_process
    @borrow_input = ""
    @borrower_name = ""
    @borrow_step = :enter_name
    @borrow_count = 0
    @borrow_index = 0
    @borrowed_books = []
    @message = ""
  end

  def reset_return_process
    @return_input = ""
    @return_borrower = nil
    @return_books = []
    @return_selected = []
    @return_message = ""
    @return_step = :enter_name
  end

  # --- Input Handling ---
def button_down(id)
  case @current_screen
  when :main_menu
    handle_main_menu_input(id)

  when :view_books
    if id == Gosu::KB_0
      @current_screen = :main_menu
    elsif id == Gosu::KB_N
      max_page = (@book_list.size - 1) / 10
      @current_page += 1 if @current_page < max_page
    elsif id == Gosu::KB_P
      @current_page -= 1 if @current_page > 0
    elsif id == Gosu::KB_S
      @search_input = ""
      @search_result = []
      @search_page = 0
      @search_mode = true
      @current_screen = :search_screen
    end

  when :add_books
    if @add_books_step == :enter_count
      if id == Gosu::KB_RETURN
        num = @add_books_input.to_i
        if num >= 1 && num <= 10
          @add_books_total = num
          @add_books_index = 0
          @add_books_list = []
          @add_books_step = :enter_id
          @add_books_input = ""
        else
          @add_books_input = ""
        end
      elsif id == Gosu::KB_BACKSPACE
        @add_books_input.chop!
      elsif id >= 30 && id <= 39
        @add_books_input += "1234567890"[id - 30]
      end

    elsif @add_books_step == :enter_id
      if id == Gosu::KB_RETURN
        new_id = @add_books_input.strip
        if new_id.length != 4 || new_id !~ /^[A-Za-z0-9]{4}$/
          @add_books_step = :duplicate
          return
        end

        exists = false
        i = 0
        while i < @book_list.size
          if @book_list[i].id.strip.downcase == new_id.downcase
            exists = true
          end
          i += 1
        end
        if !exists
          @new_book_id = new_id
          @add_books_step = :enter_title
        else
          @add_books_step = :duplicate
        end
        @add_books_input = ""
      elsif id == Gosu::KB_BACKSPACE
        @add_books_input.chop!
      elsif id >= Gosu::KB_A && id <= Gosu::KB_Z
        if button_down?(Gosu::KB_LEFT_SHIFT) || button_down?(Gosu::KB_RIGHT_SHIFT)
        @add_books_input += (65 + id - Gosu::KB_A).chr
        else
        @add_books_input += (97 + id - Gosu::KB_A).chr
        end 
      elsif id >= 30 && id <= 39
        @add_books_input += "1234567890"[id - 30]
      end
    elsif @add_books_step == :enter_title
      if id == Gosu::KB_RETURN
        @new_book_title = @add_books_input.strip
        exists = false
        i = 0
        while i < @book_list.size
          if @book_list[i].title.strip.downcase == @new_book_title.downcase
            exists = true
          end
          i += 1
        end
        if !exists
          @add_books_step = :enter_author
        else
          @add_books_step = :duplicate
        end
        @add_books_input = ""
      elsif id == Gosu::KB_BACKSPACE
        @add_books_input.chop!
      elsif id == Gosu::KB_SPACE
        @add_books_input += " "
      elsif id >= Gosu::KB_A && id <= Gosu::KB_Z
        if button_down?(Gosu::KB_LEFT_SHIFT) || button_down?(Gosu::KB_RIGHT_SHIFT)
        @add_books_input += (65 + id - Gosu::KB_A).chr
        else
        @add_books_input += (97 + id - Gosu::KB_A).chr
        end
      end

    elsif @add_books_step == :enter_author
      if id == Gosu::KB_RETURN
        new_book = Book.new(@new_book_id, @new_book_title, @add_books_input.strip, Status::AVAILABLE, "none", "none")
        @book_list << new_book
        @add_books_list << new_book
        @add_books_index += 1
        if @add_books_index >= @add_books_total
          save_new_books_to_file(@add_books_list)
          @add_books_step = :done
        else
          @add_books_step = :enter_id
        end
        @add_books_input = ""
      elsif id == Gosu::KB_BACKSPACE
        @add_books_input.chop!
      elsif id == Gosu::KB_SPACE
        @add_books_input += " "
      elsif id >= Gosu::KB_A && id <= Gosu::KB_Z
        if button_down?(Gosu::KB_LEFT_SHIFT) || button_down?(Gosu::KB_RIGHT_SHIFT)
        @add_books_input += (65 + id - Gosu::KB_A).chr
        else
        @add_books_input += (97 + id - Gosu::KB_A).chr
        end
      end

    elsif @add_books_step == :duplicate
      if id == Gosu::KB_C
        @add_books_input = ""
        @add_books_step = :enter_id
      elsif id == Gosu::KB_0
        @current_screen = :main_menu
        @add_books_message = ""
      end

    elsif @add_books_step == :done
      if id == Gosu::KB_0
        @current_screen = :main_menu
        @add_books_message = ""
      end
    end

  when :return_book
    case @return_step
    when :enter_name
      if id == Gosu::KB_RETURN
        name = @return_input.strip
        found = false
        if File.exist?("borrowers.txt")
          lines = File.readlines("borrowers.txt")
          i = 0
          while i < lines.size
            parts = lines[i].strip.split(",")
            if parts.size < 3
              i += 1
              next
            end
            borrower_name, ids, date = parts
            if borrower_name.downcase == name.downcase
              @return_borrower = { name: borrower_name, index: i }
              book_ids = ids.split(";")
              @return_books = []
              j = 0
              while j < @book_list.size
                if book_ids.include?(@book_list[j].id)
                  @return_books << @book_list[j]
                end
                j += 1
              end
              found = true
              break
            end
            i += 1
          end
        end

        if found
          @return_step = :select_books
        else
          @return_step = :not_found
        end
        @return_input = ""
      elsif id == Gosu::KB_BACKSPACE
        @return_input.chop!
      elsif id >= Gosu::KB_A && id <= Gosu::KB_Z
        if button_down?(Gosu::KB_LEFT_SHIFT) || button_down?(Gosu::KB_RIGHT_SHIFT)
        @return_input += (65 + id - Gosu::KB_A).chr
        else
        @return_input += (97 + id - Gosu::KB_A).chr
        end
      elsif id >= 30 && id <= 39
        digits = "1234567890"
        @return_input += digits[id - 30]
      end

    when :not_found
      if id == Gosu::KB_C
        @return_step = :enter_name
        @return_input = ""
      elsif id == Gosu::KB_0
        @current_screen = :main_menu
        reset_return_process
      end

    when :select_books
      if id == Gosu::KB_0
        @current_screen = :main_menu
        reset_return_process
      elsif id == Gosu::KB_A
        @return_selected = @return_books.dup
        @return_message = "Confirm return all books?"
        @return_step = :confirm_return
      elsif id >= 30 && id <= 38
        index = id - 30
        if index < @return_books.size
          @return_selected = [@return_books[index]]
          @return_message = "Return '#{@return_books[index].title}'?"
          @return_step = :confirm_return
        end
      end

    when :confirm_return
      
      i = 0
      while i < @return_selected.size
        book = @return_selected[i]
        book.status = Status::AVAILABLE
        book.borrowed_name = "none"
        book.borrowed_date = "none"
        i += 1
      end

      
      lines = File.readlines("borrowers.txt")
      borrower_line = lines[@return_borrower[:index]].strip
      name, id_str, date = borrower_line.split(",")
      all_ids = id_str.split(";")

      
      returned_ids = []
      i = 0
      while i < @return_selected.size
        returned_ids << @return_selected[i].id
        i += 1
      end

      remaining_ids = []
      i = 0
      while i < all_ids.size
        keep = true
        j = 0
        while j < returned_ids.size
          if all_ids[i] == returned_ids[j]
            keep = false
          end
          j += 1
        end
        remaining_ids << all_ids[i] if keep
        i += 1
      end

      if remaining_ids.size == 0
        lines.delete_at(@return_borrower[:index])
      else
        new_line = name + "," + remaining_ids.join(";") + "," + date
        lines[@return_borrower[:index]] = new_line
      end

      file = File.open("borrowers.txt", "w")
      i = 0
      while i < lines.size
        file.puts lines[i].strip
        i += 1
      end
      file.close

      save_books_to_file("books.txt", @book_list)
      @return_step = :done

    when :done
      if id == Gosu::KB_0
        @current_screen = :main_menu
        reset_return_process
      end
    end

  when :save_load
    case id
    when Gosu::KB_1
      save_books_to_file("books.txt", @book_list)
      @message = "Saved to books.txt successfully!"
    when Gosu::KB_2
      @book_list = load_books_from_file("books.txt")
      @message = "Loaded from books.txt successfully!"
    when Gosu::KB_0
      @message = ""
      @current_screen = :main_menu
    end

  when :borrow_book
    if @borrow_step == :has_outstanding_books && id == Gosu::KB_0
      reset_borrow_process
      @current_screen = :main_menu
      return
    end

    if @borrow_step == :error_name_error
      if id == Gosu::KB_C
        @borrow_input = ""
        @message = ""
        @borrow_step = :enter_name
        return
      elsif id == Gosu::KB_0
        reset_borrow_process
        @current_screen = :main_menu
        return
      end
    end

    if @borrow_step == :error_books
      if id == Gosu::KB_C
        @borrow_input = ""
        @message = ""
        @borrow_step = :enter_count
        return
      elsif id == Gosu::KB_0
        reset_borrow_process
        @current_screen = :main_menu
        return
      end
    end

    if @borrow_step == :error
      if id == Gosu::KB_C
        @borrow_step = :enter_book_id
        @borrow_input = ""
        @message = ""
        return
      elsif id == Gosu::KB_0
        reset_borrow_process
        @current_screen = :main_menu
        return
      end
    end

    if @borrow_step == :done && id == Gosu::KB_0
      reset_borrow_process
      @current_screen = :main_menu
      return
    end

    if @borrow_step == :confirm_existing_name
      if id == Gosu::KB_Y
        @message = "You must return previous books first."
        @borrow_step = :has_outstanding_books
      elsif id == Gosu::KB_N
        @message = "Please enter a different name."
        @borrow_input = ""
        @borrow_step = :enter_name_error
      end
      return
    end

    if @borrow_step == :enter_name_error
      if id == Gosu::KB_C
        @borrow_input = ""
        @message = ""
        @borrow_step = :enter_name
        return
      elsif id == Gosu::KB_0
        reset_borrow_process
        @current_screen = :main_menu
        return
      end
    end

    if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
      if @borrow_step == :enter_name
        @borrower_name = @borrow_input.strip
        if @borrower_name.empty?
          @message = "Name cannot be empty"
          @borrow_step = :error_name_error
        else
          existing_borrower = nil
          if File.exist?("borrowers.txt")
            file = File.open("borrowers.txt", "r")
            lines = file.readlines
            file.close
            i = 0
            while i < lines.length
              line = lines[i].strip
              parts = line.split(",")
              if parts.size < 3
                i += 1
                next
              end
              name, ids, date = parts
              if name.downcase == @borrower_name.downcase
                existing_borrower = { name: name, books: ids.split(";"), date: date }
                break
              end
              i += 1
            end
          end
          if existing_borrower
            @message = "Are you #{existing_borrower[:name]} who borrowed #{existing_borrower[:books].join(", ")} on #{existing_borrower[:date]}?"
            @borrow_step = :confirm_existing_name
          else
            @borrow_step = :enter_count
          end
        end
        @borrow_input = ""

      elsif @borrow_step == :enter_count
        count = @borrow_input.to_i
        if count <= 0
          @message = "Number must be greater than 0"
          @borrow_step = :error_books
        elsif count > 3
          @message = "You can only borrow up to 3 books"
          @borrow_step = :error_books
        else
          @borrow_count = count
          @borrow_step = :enter_book_id
          @borrow_index = 0
        end
        @borrow_input = ""

      elsif @borrow_step == :enter_book_id
        book_id = @borrow_input.strip.downcase
        found = false
        i = 0
        while i < @book_list.size
          book = @book_list[i]
          if book.id.strip.downcase == book_id
            found = true
            if book.status == Status::BORROWED
              @message = "This book is already borrowed"
              @borrow_step = :error
            else
              book.status = Status::BORROWED
              book.borrowed_name = @borrower_name
              book.borrowed_date = Time.now.strftime("%Y-%m-%d")
              @borrowed_books << book
              @borrow_index += 1
              if @borrow_index == @borrow_count
                save_books_to_file("books.txt", @book_list)
                save_borrower_record("borrowers.txt", @borrower_name, @borrowed_books)
                @borrow_step = :done
              end
            end
            break
          end
          i += 1
        end

        if !found
          @message = "This book does not exist or invalid Book ID (4 digits)"
          @borrow_step = :error
        end
        @borrow_input = ""
      end
    end

    if id == Gosu::KB_BACKSPACE
      @borrow_input.chop!
    elsif id == Gosu::KB_SPACE
      @borrow_input += " "
    elsif id >= Gosu::KB_A && id <= Gosu::KB_Z
      if button_down?(Gosu::KB_LEFT_SHIFT) || button_down?(Gosu::KB_RIGHT_SHIFT)
      @borrow_input += (65 + id - Gosu::KB_A).chr
      else
      @borrow_input += (97 + id - Gosu::KB_A).chr
      end
    elsif id >= 30 && id <= 39
      digits = "1234567890"
      @borrow_input += digits[id - 30]
    end

  when :search_screen
    if @search_mode
      if id == Gosu::KB_RETURN || id == Gosu::KB_ENTER
        keyword = @search_input.strip.downcase
        @search_result = []
        i = 0
        while i < @book_list.size
          book = @book_list[i]
          if book.id.downcase.include?(keyword) ||
             book.title.downcase.include?(keyword) ||
             book.author.downcase.include?(keyword)
            @search_result << book
          end
          i += 1
        end
        @search_page = 0
        @search_mode = false

      elsif id == Gosu::KB_BACKSPACE
        @search_input.chop!
      elsif id == Gosu::KB_SPACE
        @search_input += " "
      elsif id == 30
        @search_input += "1"
      elsif id == 31
        @search_input += "2"
      elsif id == 32
        @search_input += "3"
      elsif id == 33
        @search_input += "4"
      elsif id == 34
        @search_input += "5"
      elsif id == 35
        @search_input += "6"
      elsif id == 36
        @search_input += "7"
      elsif id == 37
        @search_input += "8"
      elsif id == 38
        @search_input += "9"
      elsif id == 39
        @search_input += "0"
      elsif id >= Gosu::KB_A && id <= Gosu::KB_Z
        if button_down?(Gosu::KB_LEFT_SHIFT) || button_down?(Gosu::KB_RIGHT_SHIFT)
        @search_input += (65 + id - Gosu::KB_A).chr
        else
        @search_input += (97 + id - Gosu::KB_A).chr
        end
      elsif id == Gosu::KB_ESCAPE
        @current_screen = :view_books
        @search_input = ""
        @search_result = []
        @search_page = 0
        @search_mode = false
      end

    else
      if id == Gosu::KB_S
        @search_input = ""
        @search_result = []
        @search_page = 0
        @search_mode = true
      elsif id == Gosu::KB_N
        max_page = (@search_result.size - 1) / 10
        @search_page += 1 if @search_page < max_page
      elsif id == Gosu::KB_P
        @search_page -= 1 if @search_page > 0
      elsif id == Gosu::KB_0
        @current_screen = :view_books
        @search_input = ""
        @search_result = []
        @search_page = 0
        @search_mode = false
      end
    end
  end
end

  def handle_menu_selection
    case @selected_index
    when 0
      @book_list = load_books_from_file("books.txt")
      @current_page = 0
      @current_screen = :view_books
    when 1
      @current_screen = :borrow_book
      @book_list = load_books_from_file("books.txt")
      reset_borrow_process
    when 2
      @current_screen = :return_book
      @book_list = load_books_from_file("books.txt")
      reset_return_process
    when 3
      @current_screen = :add_books
      @add_books_step = :enter_count
      @add_books_input = ""
      @add_books_index = 0
      @add_books_total = 0
      @add_books_list = []
      @message = ""
    when 4
      @current_screen = :save_load
    when 5
      close
    end
  end

  def handle_main_menu_input(id)
    case id
    when Gosu::KB_UP
      @selected_index = (@selected_index - 1) % @menu_options.length
    when Gosu::KB_DOWN
      @selected_index = (@selected_index + 1) % @menu_options.length
    when Gosu::KB_RETURN, Gosu::KB_ENTER
      handle_menu_selection
    when Gosu::KB_1..Gosu::KB_6
      @selected_index = id - Gosu::KB_1
      handle_menu_selection
    end
  end

  def needs_cursor?
    true
  end
end

# --- Start Application ---
window = LibraryStaffTool.new
window.show