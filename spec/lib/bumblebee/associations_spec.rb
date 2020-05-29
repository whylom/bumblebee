RSpec.describe Bumblebee::Associations do
  class Base < Bumblebee::Model; end
  class Photo < Base; end
  class User < Base; end
  class Video < Base; end

  class Article < Base
    has_many :comments
    has_many :users, uri: "articles/:id/authors"

    has_one :video
    has_one :photo, uri: "articles/:id/image"
  end

  class Comment < Base
    belongs_to :article
  end

  let(:connection) do
    stubbed_connection do |stub|
      stub.get("/articles/1")       { [200, {}, '{"title":"foreign key" }'] }
      stub.get("/articles/1/video") { [200, {}, '{"title":"moving cats" }'] }
      stub.get("/articles/1/image") { [200, {}, '{"title":"still cats" }'] }
    end
  end

  before do
    Base.connection = connection
  end

  describe "belongs_to" do
    context "when parent already has child's data" do
      let(:article) { {title: "nested data"} }
      let(:comment) { Comment.new(article: article) }

      it "does not make an API request" do
        expect(connection).not_to receive(:get)
        comment.article
      end

      it "returns an instance of the child class" do
        expect(comment.article).to be_an Article
      end

      it "populates the instance with local data" do
        expect(comment.article.title).to eq "nested data"
      end
    end

    context "when parent only has child's ID" do
      let(:comment) { Comment.new(article_id: 1) }

      it "makes an API request with the child's ID" do
        expect(connection).to receive_request(:get, "articles/1")
        comment.article
      end

      it "returns an instance of the child class" do
        expect(comment.article).to be_an Article
      end

      it "populates the instance with fetched data" do
        expect(comment.article.title).to eq "foreign key"
      end
    end
  end

  describe "has_many" do
    context "when parent already has child data" do
      let(:comments) { [{body: "best article ever"}] }
      let(:article) { Article.new(comments: comments) }

      it "returns an array of instances of the child class" do
        expect(article.comments).to be_an Array
        expect(article.comments.first).to be_a Comment
      end

      it "populates instances with the data it has" do
        expect(article.comments.first.body).to eq "best article ever"
      end
    end

    context "when parent has no child data" do
      let(:article) { Article.new(id: 1) }

      it "returns a scope for fetching child data" do
        expect(article.comments).to be_a Bumblebee::Relation
        expect(article.comments.model).to be Comment
        expect(article.comments.uri).to eq Bumblebee::URI.new('articles/1/comments')
      end

      context "when a custom URI is specified" do
        it "returns a scope with a custom URI" do
          expect(article.users).to be_a Bumblebee::Relation
          expect(article.users.model).to be User
          expect(article.users.uri).to eq Bumblebee::URI.new('articles/1/authors')
        end
      end
    end
  end

  describe "has_one" do
    context "when parent already has child data" do
      let(:video) { {title: "ferrets vs cats"} }
      let(:article) { Article.new(video: video) }

      it "does not make an API request" do
        expect(connection).not_to receive(:get)
        article.video
      end

      it "returns an instance of the child class" do
        expect(article.video).to be_a Video
      end

      it "populates the instance with local data" do
        expect(article.video.title).to eq "ferrets vs cats"
      end
    end

    context "when parent has no child data" do
      let(:article) { Article.new(id: 1) }

      it "makes an API request" do
        expect(connection).to receive_request(:get, 'articles/1/video')
        article.video
      end

      it "returns an instance of the child class" do
        expect(article.video).to be_a Video
      end

      it "populates the instance with fetched data" do
        expect(article.video.title).to eq "moving cats"
      end

      context "when a custom URI is specified" do
        it "makes an API request to the custom URI" do
          expect(connection).to receive_request(:get, 'articles/1/image')
          article.photo
        end

        it "returns an instance of the child class" do
          expect(article.photo).to be_a Photo
        end

        it "populates the instance with fetched data" do
          expect(article.photo.title).to eq "still cats"
        end
      end
    end
  end
end
