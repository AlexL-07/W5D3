require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
    include Singleton

    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end
end

class User
    attr_accessor :fname, :lname
    attr_reader :id

    def self.all
        data = QuestionsDatabase.instance.execute("select * from users")
        data.map { |datum| User.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute("select * from users where id = #{id}")
        User.new(data.first)
    end

    def self.find_by_name(fname, lname)
        data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
                SELECT *
                FROM users
                WHERE fname = ? AND lname = ?
            SQL
        # data.map { |datum| User.new(datum) }
        User.new(data.first)
    end

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
            INSERT INTO 
                users (fname, lname)
            VALUES
                (?, ?)
        SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
            UPDATE
                users 
            SET
                fname = ?, lname = ?
            WHERE
                id = ?
        SQL
    end
end

class Question
    attr_accessor :title, :body, :associated_author
    attr_reader :id

    def self.all
        data = QuestionsDatabase.instance.execute("select * from questions")
        data.map { |datum| Question.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute("select * from questions where id = ?", id)
        Question.new(data.first)
    end

    def self.find_by_title(title)
        data = QuestionsDatabase.instance.execute("select * from questions where title = '#{title}'")
        data.map { |datum| Question.new(datum) }
        # data = QuestionsDatabase.instance.execute(<<-SQL, title)
        #         SELECT *
        #         FROM questions
        #         WHERE title = ?
        #     SQL
        # data.map { |datum| Question.new(datum) }
    end

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @associated_author = options['associated_author']
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @associated_author)
            INSERT INTO 
                questions (title, body, associated_author)
            VALUES
                (?, ?, ?)
        SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @associated_author, @id)
            UPDATE
                questions 
            SET
                title = ?, body = ?, associated_author = ?
            WHERE
                id = ?
        SQL
    end 
end

class QuestionFollow
    attr_accessor :user_id, :question_id
    attr_reader :id

    def self.all
        data = QuestionsDatabase.instance.execute("select * from question_follows")
        data.map { |datum| QuestionFollow.new(datum) }
    end

    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id)
            INSERT INTO
                question_follows (user_id, question_id)
            VALUES
                (?, ?)
        SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id, @id)
            UPDATE
                question_follows
            SET
                user_id = ?, question_id = ?
            WHERE
                id = ?
        SQL
    end
end