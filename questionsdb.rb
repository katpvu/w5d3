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
    attr_accessor :id, :fname, :lname

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM users")
        data.map { |datum| User.new(datum)}
        # data
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
                users(fname, lname)
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

    def self.find_by_id(requested_id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE id = ?", requested_id)
        User.new(*data)
    end

    def self.find_by_name(fname, lname)
        data = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE fname = ? AND lname = ?", fname, lname)
        User.new(*data)
    end

    def authored_questions #returns all questions by user(self) return an array
        Question.find_by_author_id(self.id)
    end

    def authored_replies #uses reply.find_by_user_id
        Reply.find_by_user_id(self.id)
    end

    def followed_questions #return all followed questions by selected user(self)
        QuestionFollow.followed_questions_for_user_id(self.id)
    end
end

class Question 

    attr_accessor :id, :title, :body, :user_id
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
        data.map { |datum| Question.new(datum)}
    end

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @user_id = options['user_id']
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id)
            INSERT INTO
                questions(title, body, user_id)
            VALUES
                (?, ?, ?)
        SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id, @id)
            UPDATE
                questions
            SET
                title = ?, body = ?, user_id = ?
            WHERE
                id = ?
        SQL
    end

    def self.find_by_author_id(author_id) #returns all questions by selected author
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE user_id = ?", author_id)
        data.map {|datum| Question.new(datum)}
    end

    def self.find_by_id(id) #return question instance at selected id
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE id = ?", id)
        Question.new(*data)
    end

    def author #returns author of selected question and/or question.id
        data = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE id = ?", self.user_id)
        User.new(*data)
    end

    def replies #returns array of replies at selected question.id
        Reply.find_by_question_id(self.id)
    end

    def followers
        QuestionFollow.followers_for_question_id(self.id)
    end

    def self.most_followed(n = 1)
        QuestionFollow.most_followed_questions(n)
    end
end

class Reply 
    attr_accessor :id, :body, :question_id, :user_id, :reply_id
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
        data.map { |datum| Reply.new(datum)}
    end

    def initialize(options)
        @id = options['id']
        @body = options['body']
        @question_id = options['question_id']
        @user_id = options['user_id']
        @reply_id = options['reply_id']
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @body, @question_id, @user_id, @reply_id)
            INSERT INTO
                replies(body, question_id, user_id, reply_id)
            VALUES
                (?, ?, ?, ?)
        SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @body, @question_id, @user_id, @reply_id, @id)
            UPDATE
                replies
            SET
                body = ?, question_id = ?, user_id = ?, reply_id = ?
            WHERE
                id = ?
        SQL
    end

    def self.find_by_user_id(user_id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE user_id = ?", user_id)
        data.map {|datum| Reply.new(datum)}
    end

    def self.find_by_question_id(question_id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE question_id = ?", question_id)
        data.map {|datum| Reply.new(datum)}
    end

    def author
        data = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE id = ?", self.user_id)
        User.new(*data)
    end

    def question
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE id = ?", self.question_id)
        Question.new(*data)
    end

    def parent_reply #pass in id = 3, => instance in which instance.id == id3.reply_id
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE id = ?", self.reply_id)
        Reply.new(*data)
    end

    def child_replies
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE reply_id = ?", self.id)
        data.map {|datum| Reply.new(datum)}
    end
end

class QuestionFollow
    attr_accessor :id, :user_id, :question_id
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
        data.map { |datum| QuestionFollow.new(datum)}
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
                question_follows(user_id, question_id)
            VALUES
                (?, ?)
        SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update #may need semicolon, untested
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

    def self.followers_for_question_id(requested_id) #returns all the users that follow selected question id
        data = QuestionsDatabase.instance.execute(
        "SELECT
            *
        FROM
            users
        JOIN
            question_follows ON users.id = question_follows.user_id
        WHERE 
            question_id = ?", requested_id
        )
        data.map {|datum| User.new(datum)}
    end

    def self.followed_questions_for_user_id(requested_id)
        data = QuestionsDatabase.instance.execute(
            "SELECT
                *
            FROM
                question_follows
            JOIN
                questions ON question_follows.question_id = questions.id
            WHERE
                question_follows.user_id = ?", requested_id
            )   

        data.map {|datum| Question.new(datum)}
    end

    def self.most_followed_questions(n = 1)
        data = QuestionsDatabase.instance.execute(
            "SELECT
                *
            FROM
                questions
            JOIN
                question_follows ON questions.id = question_follows.question_id
            GROUP BY
                question_follows.question_id
            HAVING
                count(question_follows.question_id)
            ORDER BY
                count(question_follows.question_id) DESC
            LIMIT
                ?", n
            )
        data.map {|datum| Question.new(datum)}
    end

end

class QuestionLike

    attr_accessor :id, :question_like, :user_id, :question_id

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
        data.map { |datum| QuestionLike.new(datum)}
    end

    def initialize(options)
        @id = options['id']
        @question_like = options['question_like']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end

    def create
        raise "#{self} already in database" if @id
        QuestionsDatabase.instance.execute(<<-SQL, @question_like, @user_id, @question_id)
            INSERT INTO
                question_likes(question_like, user_id, question_id)
            VALUES
                (?, ?, ?)
        SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    end

    def update
        raise "#{self} not in database" unless @id
        QuestionsDatabase.instance.execute(<<-SQL, @question_like, @user_id, @question_id, @id)
            UPDATE
                question_likes
            SET
                question_like = ?, user_id = ?, question_id = ?
            WHERE
                id = ?
        SQL
    end

    def self.likers_for_question_id(requested_id) #returns all the users that like a certain question
        data = QuestionsDatabase.instance.execute(
        "SELECT
            *
        FROM
            users
        JOIN
            question_likes ON users.id = question_likes.user_id
        WHERE 
            question_id = ?", requested_id
        )
        data.map {|datum| User.new(datum)}
    end

    def self.num_likes_for_question_id(requested_id)
        data = QuestionsDatabase.instance.execute(
        "SELECT
            count(question_id) AS number
        FROM
            users
        JOIN
            question_likes ON users.id = question_likes.user_id
        WHERE 
            question_id = ?
        GROUP BY
            question_id", requested_id
        )
        
        data[0][0]
    end

    def self.liked_questions_for_user_id(requested_id)
        # data = QuestionsDatabase.instance.execute(
        # "SELECT
        #     *
        # FROM
        #     questions
        # JOIN
        #     question_likes ON questions.id = question_likes.user_id
        # WHERE 
        #     question_likes.user_id = ?"
        # GROUP BY
        # , requested_id
        # # )
        # data.map {|datum| Question.new(datum)}
    end
end

u = User.all
q = Question.all
r = Reply.all
f = QuestionFollow.all
l = QuestionLike.all

p QuestionLike.liked_questions_for_user_id(1)
p QuestionLike.liked_questions_for_user_id(2)