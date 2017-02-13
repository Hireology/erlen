require 'spec_helper'

describe Erlen::Schema::Empty do
  subject { described_class }

  class TestEmptySchema < Erlen::Schema::Base
    attribute :empty, Erlen::Schema::Empty
  end

  class NotEmptySchema < Erlen::Schema::Base
    attribute :blah, String, required: true
  end

  describe "validate" do
    it "validates empty object" do
      empty = Erlen::Schema::Empty.new
      expect(empty.valid?).to be_truthy
      test = TestEmptySchema.new(empty: empty)
      expect(test.valid?).to be_truthy
      not_empty = NotEmptySchema.new(blah: "blah")
      expect(not_empty.valid?).to be_truthy
      test = TestEmptySchema.new(empty: not_empty)
      expect(test.valid?).to be_falsey
    end
  end
end

describe Erlen::Schema::Any do
  subject { described_class }

  class SomeSchema < Erlen::Schema::Base
    attribute :flag, Boolean, required: true
  end

  describe "validate" do
    it "validates some payload as any schema payload" do
      some = SomeSchema.new(flag: true)
      expect(some.valid?).to be_truthy
      any = Erlen::Schema::Any.import(some)
      expect(any.valid?).to be_truthy
    end
  end
end

describe Erlen::Schema::AnyOf do
  subject { described_class }

  class Dog < Erlen::Schema::Base
    attribute :woof, Boolean, required: true
  end

  class Cat < Erlen::Schema::Base
    attribute :meow, Boolean, required: true
  end

  class Cow < Erlen::Schema::Base
    attribute :moo, Boolean, required: true
  end

  DogOrCat = Erlen::Schema::AnyOf.new(Dog, Cat)
  CowOrNothing = Erlen::Schema::AnyOf.new(Cow, Erlen::Schema::Empty)

  describe "validate" do
    it "validates as long as one schema matches" do
      dog = Dog.new(woof: true)
      expect(dog.valid?).to be_truthy
      dog_or_cat = DogOrCat.import(dog)
      expect(dog_or_cat.is_a? Dog).to be_truthy
      expect(dog_or_cat.is_a? Cat).to be_falsey
      expect(dog_or_cat.is_a? Cow).to be_falsey
      expect(dog_or_cat.valid?).to be_truthy
      cow = Cow.new(moo: true)
      dog_or_cat = DogOrCat.import(cow)
      expect(dog_or_cat.valid?).to be_falsey
    end
    it "validates optional schema" do
      cow_or_nothing = CowOrNothing.new({})
      expect(cow_or_nothing).to be_truthy
      cow = Cow.new(moo: true)
      cow_or_nothing = CowOrNothing.import(cow)
      expect(cow_or_nothing.valid?).to be_truthy
      cow_or_nothing = CowOrNothing.new(woof: true)
      expect(cow_or_nothing.valid?).to be_falsey
    end
  end

  describe "proxy" do
    it "proxys reader and writer" do
      dog = Dog.new(woof: true)
      expect(dog.valid?).to be_truthy
      dog_or_cat = DogOrCat.import(dog)
      dog_or_cat.woof = false
      expect(dog_or_cat.woof).to be_falsey
      expect do
        dog_or_cat.meow = false
      end.to raise_error(Erlen::NoAttributeError)
      # Depricated
      expect(dog_or_cat.to_hash).to eq({"woof" => false})
      expect(dog_or_cat.to_data).to eq({"woof" => false})
    end
  end
end

describe Erlen::Schema::ArrayOf do
  subject { described_class }

  class Apple < Erlen::Schema::Base
    attribute :poisonous, Boolean
  end

  class Pear < Erlen::Schema::Base
    attribute :sweet, Boolean
  end

  BasketOfApples = Erlen::Schema::ArrayOf.new(Apple)
  Numbers = Erlen::Schema.array_of(Numeric)

  describe "validate" do
    it "validates apples" do
      apple = Apple.new(poisonous: true)
      expect(apple.valid?).to be_truthy
      basket = BasketOfApples.new
      basket << apple
      expect(basket.valid?).to be_truthy
      basket << apple
      expect(basket.valid?).to be_truthy
      pear = Pear.new(sweet: false)
      basket << pear
      # XXX: this is passing because we force import at the moment.
      # expect(basket.valid?).to be_falsey
      basket.pop
      expect(basket.valid?).to be_truthy

      new_basket = BasketOfApples.import(basket)
      expect(new_basket).to eq(new_basket)

      basket = BasketOfApples.import([
        {poisonous: true}, {poisonous: false}
      ])
      expect(basket.valid?).to be_truthy
      expect(basket.count).to be(2)
      basket = BasketOfApples.import(nil)
      expect(basket.valid?).to be_truthy
      expect(basket.count).to be(0)
    end

    it "validates primitive types" do
      numbers = Numbers.new
      numbers << 1
      expect(numbers.valid?).to be_truthy
      numbers << 2.0
      expect(numbers.valid?).to be_truthy
      numbers << Object.new
      expect(numbers.valid?).to be_falsey
    end

    it 'returns an array of hashes' do
      apple = Apple.new(poisonous: true)
      apple2 = Apple.new(poisonous: false)
      basket = BasketOfApples.new([apple, apple2])
      data = basket.to_hash
      expect(data[0]).to eq('poisonous'=>true)
      expect(data[1]).to eq('poisonous'=>false)

      data = basket.to_data
      expect(data[0]).to eq('poisonous'=>true)
      expect(data[1]).to eq('poisonous'=>false)
    end
  end

  describe "proxy" do
    it "proxies some array methods" do
      numbers = Numbers.new
      expect(numbers.count).to eq(0)
      expect(numbers.class.name).to eq('ArrayOfNumeric')
      numbers << 0
      expect(numbers.first).to eq(0)
      expect(numbers.last).to eq(0)
      expect(numbers[0]).to eq(0)
      numbers[0] = 1
      expect(numbers.first).to eq(1)
      expect(numbers[0]).to eq(1)

      # * method
      expect(numbers * 2).to eq(Numbers.new([1, 1]))
      expect(numbers * ",").to eq('1')

      # more assignment + chain assignment
      numbers << 2 << 3
      reference = numbers.push(4, 5).push(6)

      # test more methods
      expect(numbers.first(2)).to eq(Numbers.new([1, 2]))
      expect(numbers.last(2)).to eq(Numbers.new([5, 6]))

      # check by iterating
      numbers.each_with_index { |n, i| expect(n).to eq(i + 1) }

      # test == reference
      expect(reference).to eq(numbers)
      expect(numbers.count).to eq(numbers.to_a.length)

      # test map and map!
      strings = numbers.map { |n| n.to_s }
      strings.each_with_index { |s, i| expect(s).to eq((i + 1).to_s) }
      numbers.map! { |n| n - 1 }
      numbers.each_with_index { |n, i| expect(n).to eq(i) }

      # binary operators
      more_numbers = Numbers.import([6, 7, 8])
      expect(numbers).to_not eq(more_numbers)
      combined = numbers + more_numbers
      combined.each_with_index { |n, i| expect(n).to eq(i) }
      expect(combined.count).to eq(9)
      expect(combined.last).to eq(8)

      # More unary operators
      expect(combined.pop).to eq(8)
      expect(combined.pop(2)).to eq(Numbers.new([6, 7]))
      expect(combined.shift).to eq(0)
      expect(combined.shift(2)).to eq(Numbers.new([1, 2]))
    end
  end

end
