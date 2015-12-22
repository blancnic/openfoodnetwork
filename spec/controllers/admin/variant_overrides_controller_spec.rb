require 'spec_helper'

describe Admin::VariantOverridesController, type: :controller do
  # include AuthenticationWorkflow

  describe "bulk_update" do
    context "json" do
      let(:format) { :json }

      let(:hub) { create(:distributor_enterprise) }
      let(:variant) { create(:variant) }
      let!(:variant_override) { create(:variant_override, hub: hub, variant: variant) }
      let(:variant_override_params) { [ { id: variant_override.id, price: 123.45, count_on_hand: 321, sku: "MySKU", on_demand: false } ] }

      context "where I don't manage the variant override hub" do
        before do
          user = create(:user)
          user.owned_enterprises << create(:enterprise)
          allow(controller).to receive(:spree_current_user) { user }
        end

        it "redirects to unauthorized" do
          spree_put :bulk_update, format: format, variant_overrides: variant_override_params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "where I manage the variant override hub" do
        before do
          allow(controller).to receive(:spree_current_user) { hub.owner }
        end

        context "but the producer has not granted VO permission" do
          it "redirects to unauthorized" do
            spree_put :bulk_update, format: format, variant_overrides: variant_override_params
            expect(response).to redirect_to spree.unauthorized_path
          end
        end

        context "and the producer has granted VO permission" do
          before do
            create(:enterprise_relationship, parent: variant.product.supplier, child: hub, permissions_list: [:create_variant_overrides])
          end

          it "allows me to update the variant override" do
            spree_put :bulk_update, format: format, variant_overrides: variant_override_params
            variant_override.reload
            expect(variant_override.price).to eq 123.45
            expect(variant_override.count_on_hand).to eq 321
            expect(variant_override.sku).to eq "MySKU"
            expect(variant_override.on_demand).to eq false
          end

          context "where params for a variant override are blank" do
            let(:variant_override_params) { [ { id: variant_override.id, price: "", count_on_hand: "", default_stock: nil, resettable: nil, sku: nil, on_demand: nil } ] }

            it "destroys the variant override" do
              spree_put :bulk_update, format: format, variant_overrides: variant_override_params
              expect(VariantOverride.find_by_id(variant_override.id)).to be_nil
            end
          end
        end
      end
    end
  end

  describe "bulk_reset" do
    context "json" do
      let(:format) { :json }

      let(:hub) { create(:distributor_enterprise) }
      let(:producer) { create(:supplier_enterprise) }
      let(:product) { create(:product, supplier: producer) }
      let(:variant1) { create(:variant, product: product) }
      let(:variant2) { create(:variant, product: product) }
      let!(:variant_override1) { create(:variant_override, hub: hub, variant: variant1, count_on_hand: 5, default_stock: 7, resettable: true) }
      let!(:variant_override2) { create(:variant_override, hub: hub, variant: variant2, count_on_hand: 2, default_stock: 1, resettable: false) }

      before do
        allow(controller).to receive(:spree_current_user) { hub.owner }
      end

      context "where the producer has not granted create_variant_overrides permission to the hub" do
        let(:params) { { format: format, variant_overrides: [ { id: variant_override1.id } ] } }

        it "restricts access" do
          spree_put :bulk_reset, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "where the producer has granted create_variant_overrides permission to the hub" do
        let!(:er1) { create(:enterprise_relationship, parent: producer, child: hub, permissions_list: [:create_variant_overrides]) }

        context "where reset is enabled" do
          let(:params) { { format: format, variant_overrides: [ { id: variant_override1.id } ] } }

          it "updates stock to default values" do
            spree_put :bulk_reset, params
            expect(variant_override1.reload.count_on_hand).to eq 7
          end
        end

        context "where reset is disabled" do
          let(:params) { { format: format, variant_overrides: [ { id: variant_override2.id } ] } }

          it "doesn't update on_hand" do
            spree_put :bulk_reset, params
            expect(variant_override2.reload.count_on_hand).to eq 2
          end
        end
      end
    end
  end
end
