RSpec.describe Bumblebee::Model do
  let(:model) { Bumblebee::Model }

  let(:connection) { stubbed_connection }
  before { model.connection = connection }

  describe '.uri' do
    let(:model) { create_model('Apple') }

    describe 'by default' do
      it "uses a URI template based on the model's name" do
        expect(model.uri).to eq Bumblebee::URI.new('apples/:id')
      end
    end

    describe 'given a custom URI template' do
      before { model.uri 'oranges/:id' }

      it 'uses the custom template provided' do
        expect(model.uri).to eq Bumblebee::URI.new('oranges/:id')
      end
    end
  end

  describe '.scope' do
    before do
      model.scope :one, ->{ where(one: 1) }
      model.scope :two, ->{ where(two: 2) }
    end

    let(:scope) { model.one.two }

    it 'creates a chainable named scope' do
      expect(scope).to be_a Bumblebee::Relation
      expect(scope.params).to eq(one: 1, two: 2)
    end
  end

  describe '.all' do
    let(:scope) { model.all }

    it 'returns a blank scope' do
      expect(scope).to be_a Bumblebee::Relation
      expect(scope.params).to be_empty
      expect(scope.headers).to be_empty
    end
  end

  describe '.where' do
    let(:scope) { model.where(a: 1) }

    it 'returns a scope with the given params' do
      expect(scope).to be_a Bumblebee::Relation
      expect(scope.params).to eq(a: 1)
    end
  end

  describe '.header' do
    let(:scope) { model.header(b: 2) }

    it 'returns a scope with the given headers' do
      expect(scope).to be_a Bumblebee::Relation
      expect(scope.headers).to eq(b: 2)
    end
  end

  describe '.load' do
    let(:instance) { model.load(foo: 'bar') }

    it 'returns an instance of the model class' do
      expect(instance).to be_a Bumblebee::Model
    end

    it 'populates the instance with the given attributes' do
      expect(instance.attributes).to match(foo: 'bar')
    end

    it 'sets the persisted flag to true' do
      expect(instance).to be_persisted
    end
  end

  describe 'creating' do
    let(:connection) do
      stubbed_connection do |stub|
        stub.post('/models') { [status, {}, '{}'] }
      end
    end

    let(:params) { {foo: 'bar'} }

    describe '.create' do
      context 'when response is a success' do
        let(:status) { 200 }
        subject { model.create(params) }

        it { is_expected.to be_a model }
        it { is_expected.to be_persisted }

        it 'is populated with the given params' do
          expect(subject.attributes).to match(params)
        end
      end

      context 'when response is not a success' do
        let(:status) { 500 }

        it { is_expected.to be_a model }
        it { is_expected.not_to be_persisted }
      end
    end

    describe '.create!' do
      context 'when response is a success' do
        let(:status) { 200 }
        subject { model.create!(params) }

        it { is_expected.to be_a model }
        it { is_expected.to be_persisted }

        it 'is populated with the given params' do
          expect(subject.attributes).to match(params)
        end
      end

      context 'when response is not a success' do
        let(:status) { 500 }

        it 'raises an error' do
          expect { model.create!(params) }.to raise_error(Bumblebee::RequestError)
        end
      end
    end
  end

  describe '.find' do
    let(:connection) do
      stubbed_connection do |stub|
        stub.get('/models/123') { [200, {}, '{"foo":"bar"}'] }
      end
    end

    it 'makes a request to the expected URI' do
      expect(connection).to receive_request(:get, 'models/123')
      model.find(123)
    end

    it 'returns a populated instance of the model class' do
      instance = model.find(123)
      expect(instance).to be_a Bumblebee::Model
      expect(instance.attributes).to match(foo: 'bar')
    end

    it 'raises an error if no ID is provided' do
      expect { model.find }.to raise_error(ArgumentError)
    end
  end

  describe '.find_by' do
    let(:connection) do
      stubbed_connection do |stub|
        stub.get('/models?game=on') { [200, {}, '[{"foo":"bar"}]'] }
      end
    end

    it 'makes a request to the expected URI' do
      expect(connection).to receive_request(:get, 'models', a_hash_including(game: 'on'))
      model.find_by(game: 'on')
    end

    it 'returns a populated instance of the model class' do
      instance = model.find_by(game: 'on')
      expect(instance).to be_a Bumblebee::Model
      expect(instance.attributes).to match(foo: 'bar')
    end
  end

  describe '.request' do
    let(:connection) do
      stubbed_connection do |stub|
        stub.get('/foo') { [status, {}, "{}"] }
      end
    end

    let(:status) { 200 }
    let(:request) { model.request(:get, 'foo') }

    before do
      model.connection = connection
    end

    it 'delegates the request to its connection' do
      expect(connection).to receive_request(:get, 'foo')
      request
    end

    context 'when the response is not a success' do
      let(:status) { 404 }
      it 'raises if the response was not a success' do
        expect{ request }.to raise_error(Bumblebee::RequestError)
      end
    end
  end

  describe 'saving' do
    let(:connection) do
      stubbed_connection do |stub|
        stub.post('/models') { response }
        stub.put('/models/1')  { response }
      end
    end

    let(:success) { [200, {}, '{}'] }
    let(:failure) { [422, {}, '{"errors": {"email": ["cannot be blank"]}}'] }

    describe '#save' do
      context 'when creating' do
        let(:record) { model.new }

        context 'when successful' do
          let(:response) { success }

          it 'returns true' do
            expect(record.save).to eq true
          end
        end

        context 'when unsuccessful' do
          let(:response) { failure }

          it 'returns false' do
            expect(record.save).to eq false
          end

          it 'populates errors' do
            record.save
            expect(record.errors).to match(email: ['cannot be blank'])
          end
        end
      end

      context 'when updating' do
        let(:record) { model.load(id: 1) }

        context 'when successful' do
          let(:response) { success }

          it 'returns true' do
            expect(record.save).to eq true
          end
        end

        context 'when unsuccessful' do
          let(:response) { failure }

          it 'returns false' do
            expect(record.save).to eq false
          end

          it 'populates errors' do
            record.save
            expect(record.errors).to match(email: ['cannot be blank'])
          end
        end
      end
    end

    describe '#save!' do
      context 'when creating' do
        let(:record) { model.new }

        context 'when successful' do
          let(:response) { success }

          it 'returns true' do
            expect(record.save!).to eq true
          end
        end

        context 'when unsuccessful' do
          let(:response) { failure }

          it 'raises an error' do
            expect { record.save! }.to raise_error(Bumblebee::RequestError)
          end

          it 'populates errors' do
            record.save! rescue nil
            expect(record.errors).to match(email: ['cannot be blank'])
          end
        end
      end

      context 'when updating' do
        let(:record) { model.load(id: 1) }

        context 'when successful' do
          let(:response) { success }

          it 'returns true' do
            expect(record.save!).to eq true
          end
        end

        context 'when unsuccessful' do
          let(:response) { failure }

          it 'raises an error' do
            expect { record.save! }.to raise_error(Bumblebee::RequestError)
          end

          it 'populates errors' do
            record.save! rescue nil
            expect(record.errors).to match(email: ['cannot be blank'])
          end
        end
      end
    end

    describe '#update' do
      let(:record)  { model.load(id: 1, name: 'Brooks') }

      context 'when successful' do
        let(:response) { success }

        it 'returns true' do
          expect(record.update(name: 'Schnooks')).to eq true
        end

        it 'updates the attributes provided' do
          expect { record.update(name: 'Schnooks') }.to change { record.name }
        end
      end

      context 'when unsuccessful' do
        let(:response) { failure }

        it 'returns false' do
          expect(record.update(name: 'Schnooks')).to eq false
        end

        it 'populates errors' do
          record.update(name: 'Schnooks')
          expect(record.errors).to match(email: ['cannot be blank'])
        end
      end
    end

    describe '#update!' do
      let(:record)  { model.load(id: 1, name: 'old') }

      context 'when successful' do
        let(:response) { success }

        it 'returns true' do
          expect(record.update!(name: 'new')).to eq true
        end

        it 'updates the attributes provided' do
          expect { record.update!(name: 'new') }.to change { record.name }
        end
      end

      context 'when unsuccessful' do
        let(:response) { failure }

        it 'raises an error' do
          expect { record.update!(name: 'new') }.to raise_error(Bumblebee::RequestError)
        end

        it 'populates errors' do
          record.update!(name: 'new') rescue nil
          expect(record.errors).to match(email: ['cannot be blank'])
        end
      end
    end
  end

  describe '#reload' do
    let(:connection) do
      stubbed_connection do |stub|
        stub.get('/models/1') { [200, {}, '{"id":1,"name":"Barry"}'] }
      end
    end

    let(:original) { model.new(id: 1, name: "Larry") }
    let(:reloaded) { original.reload }

    it 'returns self' do
      expect(reloaded).to be original
    end

    it 'updates attributes' do
      expect(reloaded.name).to eq 'Barry'
    end
  end

  describe '#destroy' do
    let(:connection) do
      stubbed_connection do |stub|
        stub.delete('/models/1') { [200, {}, "{}"] }
      end
    end

    let(:instance) { model.new(id: 1) }

    context "with an unsaved instance" do
      before do
        instance.persisted = false
      end

      it "calls destroy_new on destroy" do
        expect(instance).to receive(:destroy_new)
        instance.destroy
      end

      it "doesn't make a request" do
        expect(model).not_to receive(:request)
        instance.destroy
      end

      it "returns true as a success indicator" do
        expect(instance.destroy).to be true
      end
    end

    context "with a saved instance" do
      before do
        instance.persisted = true
      end

      it "calls destroy_existing on destroy" do
        expect(instance).to receive(:destroy_existing)
        instance.destroy
      end

      it "is unpersisted after a destroy" do
        instance.destroy
        expect(instance).not_to be_persisted
      end

      it "makes a delete request" do
        expect(model).to receive(:request).with(:delete, eq("models/1"), {})
        instance.destroy
      end

      it "returns true as a success indicator" do
        expect(instance.destroy).to be true
      end

      context "with errors on destroy" do
        let(:connection) do
          stubbed_connection do |stub|
            stub.delete('/models/1') { [422, {}, %({"errors": {"name": ["error"]}})] }
          end
        end

        it "provides access to the parsed errors hash" do
          instance.destroy
          expect(instance.errors).to match(name: ["error"])
        end

        it "doesn't mark the model as unpersisted" do
          instance.destroy
          expect(instance).to be_persisted
        end

        it "returns false as a failure indicator" do
          expect(instance.destroy).to be false
        end
      end
    end
  end

  describe '#destroy!' do
  end
end
