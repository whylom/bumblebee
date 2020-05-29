RSpec.describe Bumblebee::Pager do
  let(:model) { Bumblebee::Model }
  let(:scope) { Bumblebee::Relation.new(model) }
  let(:pager) { described_class.new(scope) }

  let(:headers) { {'X-Total' => 3, 'X-Total-Pages' => 3} }

  before do
    model.connection = stubbed_connection do |stub|
      stub.get('/models?page=1') { [200, headers, '[{"name": "page 1"}]'] }
      stub.get('/models?page=2') { [200, headers, '[{"name": "page 2"}]'] }
      stub.get('/models?page=3') { [200, headers, '[{"name": "page 3"}]'] }

      # have to define this one last for the others to work
      stub.get('/models') { [200, {'X-Total-Pages' => 3}, '[{"name": "page 1"}]'] }
    end
  end

  describe '#count' do
    it 'returns the total number of pages' do
      expect(pager.count).to eq 3
    end
  end

  describe '#first' do
    it 'returns the first page of records' do
      expect(pager.first.map(&:name)).to match ['page 1']
    end
  end

  describe '#last' do
    it 'returns the last page of records' do
      expect(pager.last.map(&:name)).to match ['page 3']
    end
  end

  describe '#at' do
    it 'returns the requested page of records' do
      expect(pager.at(2).map(&:name)).to match ['page 2']
    end
  end

  describe '#[]' do
    it 'returns the requested page of records' do
      expect(pager[2].map(&:name)).to match ['page 2']
    end
  end

  describe '#each' do
    context 'when a block is provided' do
      it 'yields once for each page' do
        expect { |block| pager.each(&block) }.to yield_control.exactly(3).times
      end
    end

    context 'when a block is not provided' do
      it 'returns an enumerator for all pages' do
        expect(pager.each).to be_an Enumerator

        page1, page2, page3 = pager.each.to_a
        expect(page1.first.name).to eq 'page 1'
        expect(page2.first.name).to eq 'page 2'
        expect(page3.first.name).to eq 'page 3'
      end
    end
  end
end
