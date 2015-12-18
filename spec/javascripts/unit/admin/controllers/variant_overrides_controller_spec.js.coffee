describe "VariantOverridesCtrl", ->
  ctrl = null
  scope = null
  hubs = [{id: 1, name: 'Hub'}]
  producers = [{id: 2, name: 'Producer'}]
  products = [{id: 1, name: 'Product'}]
  hubPermissions = {}
  VariantOverrides = null
  variantOverrides = {}
  DirtyVariantOverrides = null
  dirtyVariantOverrides = {}
  StatusMessage = null
  statusMessage = {}

  beforeEach ->
    module 'admin.variantOverrides'
    module ($provide) ->
      $provide.value 'SpreeApiKey', 'API_KEY'
      $provide.value 'variantOverrides', variantOverrides
      $provide.value 'dirtyVariantOverrides', dirtyVariantOverrides
      null
    scope = {}

    inject ($controller, _VariantOverrides_) ->
      VariantOverrides = _VariantOverrides_
      ctrl = $controller 'AdminVariantOverridesCtrl', { $scope: scope, hubs: hubs, producers: producers, products: products, hubPermissions: hubPermissions, VariantOverrides: _VariantOverrides_ }

  it "initialises the hub list and the chosen hub", ->
    expect(scope.hubs).toEqual { 1: {id: 1, name: 'Hub'} }
    expect(scope.hub).toBeNull()

  it "initialises select filters", ->
    expect(scope.producerFilter).toEqual 0
    expect(scope.query).toEqual ''

  it "adds products", ->
    spyOn(VariantOverrides, "ensureDataFor")
    expect(scope.products).toEqual []
    scope.addProducts ['a', 'b']
    expect(scope.products).toEqual ['a', 'b']
    scope.addProducts ['c', 'd']
    expect(scope.products).toEqual ['a', 'b', 'c', 'd']
    expect(VariantOverrides.ensureDataFor).toHaveBeenCalled()

  describe "selecting a hub", ->
    it "sets the chosen hub", ->
      scope.hub_id = 1
      scope.selectHub()
      expect(scope.hub).toEqual hubs[0]

    it "does nothing when no selection has been made", ->
      scope.hub_id = ''
      scope.selectHub
      expect(scope.hub).toBeNull

  describe "updating", ->
    describe "error messages", ->
      it "returns an unauthorised message upon 401", ->
        expect(scope.updateError({}, 401)).toEqual "I couldn't get authorisation to save those changes, so they remain unsaved."

      it "returns errors when they are provided", ->
        data = {errors: {base: ["Hub can't be blank", "Variant can't be blank"]}}
        expect(scope.updateError(data, 400)).toEqual "I had some trouble saving: Hub can't be blank, Variant can't be blank"

      it "returns a generic message otherwise", ->
        expect(scope.updateError({}, 500)).toEqual "Oh no! I was unable to save your changes."

  describe "setting stock to defaults", ->
    it "prompts to save changes if there are any pending", ->
      spyOn(VariantOverrides,"resetStock")
      DirtyVariantOverrides.add {hub_id: 1, variant_id: 1}
      scope.resetStock
      #expect(scope.StatusMessage.statusMessage.text).toMatch "changes"
      expect(VariantOverrides.resetStock).not.toHaveBeenCalled
    it "updates and refreshes on hand value for variant overrides with a default stock level", ->
      spyOn(VariantOverrides,"resetStock")
      scope.resetStock
      expect(VariantOverrides.resetStock).toHaveBeenCalled
      #expect(scope.StatusMessage.statusMessage.text).toMatch "defaults"
