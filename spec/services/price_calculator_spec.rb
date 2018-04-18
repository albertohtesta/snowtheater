require 'rails_helper'

RSpec.describe PriceCalculator, :aggregate_failures do
  let(:ticket_one) { instance_double(Ticket, price: Money.new(1500)) }
  let(:ticket_two) { instance_double(Ticket, price: Money.new(2000)) }
  let(:calculator) { PriceCalculator.new(
    [ticket_one, ticket_two], discount_code) }
  
  describe "without a discount code" do
    let(:discount_code) { NullDiscountCode.new }
    
    it "calculates the price of a list of tickets" do
      expect(discount_code.multiplier).to eq(1.0)
      expect(discount_code.percentage_float).to eq(0)
      expect(calculator.subtotal).to eq(Money.new(3500))
      expect(calculator.discount).to eq(Money.new(0))
      expect(calculator.processing_fee).to eq(Money.new(100))
      expect(calculator.breakdown).to match(
        ticket_cents: [1500, 2000], processing_fee_cents: 100)
      expect(calculator.total_price).to eq(Money.new(3600))
    end
  end
  
  describe "with an applicable discount code" do
    let(:discount_code) { DiscountCode.new(percentage: 25) }
    
    it "calculates the total price and discount" do
      expect(discount_code.multiplier).to eq(0.75)
      expect(discount_code.percentage_float).to eq(0.25)
      expect(calculator.discount).to eq(Money.new(875))
      expect(calculator.processing_fee).to eq(Money.new(100))
      expect(calculator.breakdown).to eq(
        ticket_cents: [1500, 2000], processing_fee_cents: 100,
        discount_cents: -875)
      expect(calculator.total_price).to eq(Money.new(2725))
    end
  end
  
  describe "with a free ticket" do
    let(:discount_code) { DiscountCode.new(percentage: 100) }
    
    it "calculates the total price and discount" do
      expect(discount_code.multiplier).to eq(0)
      expect(discount_code.percentage_float).to eq(1)
      expect(calculator.discount).to eq(Money.new(3500))
      expect(calculator.processing_fee).to eq(Money.zero)
      expect(calculator.breakdown).to eq(
        ticket_cents: [1500, 2000], discount_cents: -3500)
      expect(calculator.total_price).to eq(Money.zero)
    end
  end
  
  describe "with a discount code with a good min value" do
    let(:discount_code) { DiscountCode.new(
      percentage: 25, minimum_amount_cents: 100) }
    
    it "calculates the total price and discount" do
      expect(discount_code.multiplier).to eq(0.75)
      expect(discount_code.percentage_float).to eq(0.25)
      expect(calculator.total_price).to eq(Money.new(2725))
      expect(calculator.discount).to eq(Money.new(875))
    end
  end
  
  describe "with a discount code with a bad min value" do
    let(:discount_code) { DiscountCode.new(
      percentage: 25, minimum_amount_cents: 5000) }
    
    it "calculates the total price and discount" do
      expect(calculator.total_price).to eq(Money.new(3600))
      expect(calculator.discount).to eq(Money.new(0))
    end
  end
  
  describe "with an applicable discount code under max" do
    let(:discount_code) { DiscountCode.new(
      percentage: 25, maximum_discount_cents: 10_000) }
    
    it "calculates the total price and discount" do
      expect(discount_code.multiplier).to eq(0.75)
      expect(discount_code.percentage_float).to eq(0.25)
      expect(calculator.total_price).to eq(Money.new(2725))
      expect(calculator.discount).to eq(Money.new(875))
    end
  end
  
  describe "with an applicable discount code over max" do
    let(:discount_code) { DiscountCode.new(
      percentage: 25, maximum_discount_cents: 500) }
    
    it "calculates the total price and discount" do
      expect(discount_code.multiplier).to eq(0.75)
      expect(discount_code.percentage_float).to eq(0.25)
      expect(calculator.total_price).to eq(Money.new(3100))
      expect(calculator.discount).to eq(Money.new(500))
    end
  end
  
  describe "with a shipping fee" do
    let(:calculator) { PriceCalculator.new(
      [ticket_one, ticket_two], discount_code, :standard) }
    let(:discount_code) { NullDiscountCode.new }
    
    it "calculates the price of a list of tickets" do
      expect(discount_code.multiplier).to eq(1.0)
      expect(discount_code.percentage_float).to eq(0)
      expect(calculator.subtotal).to eq(Money.new(3500))
      expect(calculator.discount).to eq(Money.new(0))
      expect(calculator.processing_fee).to eq(Money.new(100))
      expect(calculator.breakdown).to match(
        ticket_cents: [1500, 2000], processing_fee_cents: 100,
        shipping_cents: 200)
      expect(calculator.total_price).to eq(Money.new(3800))
    end
  end
end