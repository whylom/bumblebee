RSpec.describe Bumblebee::URI do
  describe '#to_s' do
    context 'when the template has no variables' do
      it 'returns the template untouched' do
        uri = Bumblebee::URI.new('users', id: 1)
        expect( uri.to_s ).to eq 'users'
      end
    end

    context "when the template doesn't match any params" do
      it 'omits the variable' do
        uri = Bumblebee::URI.new('users/:id', ego: 1)
        expect( uri.to_s ).to eq 'users'
      end
    end

    context 'when the populated template has empty directories' do
      it 'removes doubled & trailing slashes' do
        uri = Bumblebee::URI.new(':foo/:bar/:baz')
        expect( uri.to_s ).not_to include('//')
        expect( uri.to_s ).not_to end_with('/')
      end
    end
  end

  describe '#with' do
    let(:model_class) { Class.new(Bumblebee::Model) }

    it 'returns a new instance of Bumblebee::URI' do
      uri = Bumblebee::URI.new(':id')
      expect( uri.with(1) ).to be_a Bumblebee::URI
      expect( uri.with(1) ).not_to be uri
    end

    context 'given a hash' do
      it 'populates the template' do
        uri = Bumblebee::URI.new(':one/:two')
        expect( uri.with(one: 1, two: 2) ).to eq '1/2'
      end
    end

    context 'given a model' do
      it "populates the template with the model's attributes" do
        uri = Bumblebee::URI.new(':one/:two')
        model = model_class.new(one: 1, two: 2)
        expect( uri.with(model) ).to eq '1/2'
      end
    end

    context 'given an integer or string' do
      it 'treats the argument like an id' do
        uri = Bumblebee::URI.new(':id')
        expect( uri.with(1)   ).to eq '1'
        expect( uri.with('1') ).to eq '1'
      end
    end
  end

  describe '#append' do
    it 'appends a string to the URI' do
      uri = Bumblebee::URI.new('users')
      expect( uri.append('feet') ).to eq 'users/feet'
      expect( uri.append(:feet)  ).to eq 'users/feet'
    end

    it 'plays nicely with templating' do
      uri = Bumblebee::URI.new('users/:id')
      expect( uri.append('shoes')         ).to eq 'users/shoes'
      expect( uri.append('shoes').with(1) ).to eq 'users/1/shoes'
    end

    it 'returns a new instance of Bumblebee::URI' do
      uri = Bumblebee::URI.new('this')
      expect( uri.append('that') ).to be_a Bumblebee::URI
      expect( uri.append('that') ).not_to be uri
    end
  end

  describe '#clone' do
    let(:original) { Bumblebee::URI.new('users/:id', id: 123) }
    let(:clone) { original.clone }

    it 'returns a copy' do
      expect(clone).to be_a Bumblebee::URI
      expect(clone).not_to be original
    end

    it 'also clones the template and params' do
      expect(clone.template).to eql('users/:id')
      expect(clone.template).not_to be(original.template)

      expect(clone.params).to eql(id: 123)
      expect(clone.params).not_to be(original.params)
    end
  end
end
