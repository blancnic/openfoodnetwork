require 'spec_helper'

describe Customer, type: :model do
  describe 'creation callbacks' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:enterprise) { create(:distributor_enterprise) }

    it "associates no user using non-existing email" do
      c = Customer.create(enterprise: enterprise, email: 'some-email-not-associated-with-a-user@email.com')
      expect(c.user).to be_nil
    end

    it "associates an existing user using email" do
      non_existing_email = 'some-email-not-associated-with-a-user@email.com'
      c1 = Customer.create(enterprise: enterprise, email: non_existing_email, user: user1)
      expect(c1.user).to eq user1
      expect(c1.email).to eq non_existing_email
      expect(c1.email).to_not eq user1.email

      c2 = Customer.create(enterprise: enterprise, email: user2.email)
      expect(c2.user).to eq user2
    end

    it "associates an existing user using email case-insensitive" do
      c = Customer.create(enterprise: enterprise, email: user2.email.upcase)
      expect(c.user).to eq user2
    end
  end
end
