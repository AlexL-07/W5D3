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

    def self.liked_questions
        QuestionLikes.liked_questions_for_user_id(@id)
    end
    
    def authored_questions
        arr_qs = []
        arr_qs << Question.find_by_author_id(@id)
        arr_qs
    end

    def authored_replies
        arr_rs = []
        arr_rs << Reply.find_by_user_id(@id)
        arr_rs
    end

    def followed_questions
        QuestionFollow.followed_questions_for_user_id(@id)
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

    def self.find_by_author_id(author_id)
        data = QuestionsDatabase.instance.execute("select * from questions where associated_author = ?", author_id)
        Question.new(data.first)
    end

    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

    def replies
        arr_rs = []
        arr_rs << Reply.find_by_question_id(@id)
        arr_rs
    end

    def author
        User.find_by_id(associated_author)
    end

    def followers
        QuestionFollow.followers_for_question_id(@id)
    end

    def likers
        QuestionLikes.likers_for_question_id(@id)
    end

    def num_likes
        QuestionLikes.num_likes_for_question_id(@id)
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

    def self.followers_for_question_id(question_id)
        users_ids = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT users.id
            FROM users
            JOIN question_follows ON users.id = question_follows.user_id
            JOIN questions ON questions.id = question_follows.question_id 
            WHERE questions.id = ?
            SQL
        users_ids.map { |hash_id| User.find_by_id(hash_id["id"]) }
    end

    def self.followed_questions_for_user_id(follower_user_id)
        questions_ids = QuestionsDatabase.instance.execute(<<-SQL, follower_user_id)
            SELECT questions.id
            FROM questions
            JOIN question_follows ON question_follows.question_id = questions.id
            JOIN users ON question_follows.user_id = users.id
            WHERE users.id = ?
            SQL
        questions_ids.map {|hash_id| Question.find_by_id(hash_id["id"])}
    end

    def self.most_followed_questions(n)
        questions_ids = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT questions.id
        FROM questions
        JOIN question_follows ON question_follows.question_id = questions.id
        JOIN users ON question_follows.user_id = users.id
        GROUP BY questions.id
        ORDER BY COUNT(users.id) DESC
        LIMIT ?
        SQL
        questions_ids.map {|hash_id| Question.find_by_id(hash_id["id"])}
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

class Reply
    attr_accessor :user_id, :question_id, :reply_id, :text
    attr_reader :id

    def self.all
        data = QuestionsDatabase.instance.execute("select * from replies")
        data.map { |datum| Reply.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute("select * from replies where id = ?", id)
        Reply.new(data.first)
    end

    def self.find_by_user_id(user_id)
        data = QuestionsDatabase.instance.execute("select * from replies where user_id = ?", user_id)
        Reply.new(data.first)
    end

    def self.find_by_question_id(question_id)
        data = QuestionsDatabase.instance.execute("select * from replies where question_id = ?", question_id)
        data.map { |datum| Reply.new(datum) }
    end

    def parent_reply
        data = QuestionsDatabase.instance.execute("select * from replies where id = ?", reply_id)
        Reply.new(data.first)
    end

    def child_replies
        data = QuestionsDatabase.instance.execute(<<-SQL, @id)
            SELECT *
            FROM replies
            WHERE reply_id = ?
        SQL
        data.map {|datum| Reply.new(datum) }
    end

    def author
        User.find_by_id(@user_id)
    end

    def question
        Question.find_by_id(@question_id)
    end


    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
        @reply_id = options['reply_id']
        @body = options['body']
        
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id, @reply_id, @body)
            INSERT INTO 
                replies (user_id, question_id, reply_id, body)
            VALUES
                (?, ?, ?, ?)
        SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id, @reply_id, @body, @id)
            UPDATE
                replies 
            SET
                user_id = ?, question_id = ?, reply_id = ?, body = ?
            WHERE
                id = ?
        SQL
    end
end

class QuestionLikes
    attr_accessor :liked, :user_id, :question_id
    attr_reader :id

    def self.all
        data = QuestionsDatabase.instance.execute('select * from question_likes')
        data.map { |datum| QuestionLikes.new(datum) }
    end

    def self.likers_for_question_id(questions_id)
        users_ids = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
            SELECT users.id
            FROM users
            JOIN question_likes ON users.id = question_likes.user_id
            JOIN questions ON question_likes.question_id = questions.id
            WHERE questions.id = ? AND question_likes.liked != 0
            SQL
        users_ids.map {|id| User.find_by_id(id['id'])}
    end

    def self.num_likes_for_question_id(question_id)
        num_likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT COUNT(*)
            FROM users
            JOIN question_likes ON users.id = question_likes.user_id
            JOIN questions ON question_likes.question_id = questions.id
            WHERE questions.id = ? AND question_likes.liked != 0
            SQL
        num_likes.first.values[0]
    end

    def self.liked_questions_for_user_id(users_id)
        question_ids = QuestionsDatabase.instance.execute(<<-SQL, users_id)
            SELECT questions.id
            FROM questions
            JOIN question_likes ON questions.id = question_likes.question_id 
            JOIN users ON question_likes.user_id = users.id
            WHERE users.id = ? AND question_likes.liked != 0
        SQL
        question_ids.map {|id| Question.find_by_id(id['id'])}
    end


    def initialize(options)
        @id = options['id']
        @liked = options['liked']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @liked, @user_id, @question_id)
            INSERT INTO
                question_likes (liked, user_id, question_id)
            VALUES
                (?, ?, ?)
        SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @liked, @user_id, @question_id, @id)
            UPDATE
                question_likes
            SET
                liked = ?, user_id = ?, question_id = ?
            WHERE
                id = ?
        SQL
    end
end

