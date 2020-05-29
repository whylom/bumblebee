RSpec.describe Bumblebee::Relation do
  let(:model) { Bumblebee::Model }
  let(:scope) { Bumblebee::Relation.new(model) }

  let(:headers) { {'X-Total' => 6, 'X-Total-Pages' => 3} }

  before do
    model.connection = stubbed_connection do |stub|
      stub.get('/models?page=1') { [200, headers, '[{"id": 1},{"id": 2}]'] }
      stub.get('/models?page=2') { [200, headers, '[{"id": 3},{"id": 4}]'] }
      stub.get('/models?page=3') { [200, headers, '[{"id": 5},{"id": 6}]'] }

      # have to define this one last for the others to work
      stub.get('/models') { [200, headers, '[{"id": 1},{"id": 2}]'] }
    end
  end

  describe '#where' do
    let(:result) { scope.where(a: 1) }

    it 'returns a modified copy' do
      expect(result).not_to be scope
      expect(result.params).to eq(a: 1)
    end

    it 'merges the new params into the old' do
      expect( result.where(b: 2).params ).to eq(a: 1, b: 2)
    end
  end

  describe '#header' do
    let(:result) { scope.header(a: 1) }

    it 'returns a modified copy' do
      expect(result).not_to be scope
      expect(result.headers).to eq(a: 1)
    end

    it 'merges the new headers into the old' do
      expect( result.header(b: 2).headers ).to eq(a: 1, b: 2)
    end
  end

  describe '#get' do
    let(:uri) { model.uri }

    context 'when the scope is blank' do
      it 'makes a request with no params or headers' do
        expect(model).to receive(:request).with(:get, uri, {}, {})
        scope.get
      end
    end

    context 'when the scope has params & headers' do
      let(:scope) { model.where(a: 1).header(b: 2) }

      it 'make a request with those params & headers' do
        expect(model).to receive(:request).with(:get, uri, { a: 1 }, { b: 2 })
        scope.get
      end
    end

    context 'when the scope has a custom URI' do
      let(:custom_uri) { Bumblebee::URI.new('sheep/:id') }
      let(:scope) { Bumblebee::Relation.new(model, uri: custom_uri) }

      it 'makes a request for that URI' do
        expect(model).to receive(:request).with(:get, custom_uri, {}, {})
        scope.get
      end
    end
  end

  describe '#first' do
    it 'returns the first record on the first page' do
      expect(scope.first.id).to eq 1
    end
  end

  describe '#last' do
    it 'returns the last record on the last page' do
      expect(scope.last.id).to eq 6
    end
  end

  describe '#pages' do
    it 'returns a Bumblebee::Pager bound to the current scope' do
      expect(scope.pages).to be_a Bumblebee::Pager
      expect(scope.pages.scope).to be scope
    end
  end

  describe '#count' do
    it 'returns the total returned from the API' do
      expect(scope.count).to eq(6)
    end
  end

  describe '#each' do
    context 'when a block is provided' do
      it 'yields once for each record, across pages' do
        expect { |block| scope.each(&block) }.to yield_control.exactly(6).times
      end
    end

    context 'when a block is not provided' do
      it 'returns an enumerator for all records' do
        expect(scope.each).to be_an Enumerator
        expect(scope.each.map(&:id)).to match [1,2,3,4,5,6]
      end
    end
  end

  describe '#to_a' do
    it 'returns an array with all records' do
      expect(scope.to_a.map(&:id)).to match [1,2,3,4,5,6]
    end
  end

  describe 'a chained scope' do
    let(:model) { create_model }

    before do
      model.scope :one, ->{ where(a: 1) }
      model.scope :two, ->{ where(b: 2) }
    end

    it 'delegates to its model' do
      expect(model.one.two.params).to eq(a: 1, b: 2)
    end
  end
end
