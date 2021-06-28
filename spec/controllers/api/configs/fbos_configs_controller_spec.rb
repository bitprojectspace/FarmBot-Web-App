require "spec_helper"

describe Api::FbosConfigsController do
  include Devise::Test::ControllerHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:device) { user.device }

  describe "#show" do
    it "handles requests" do
      sign_in user
      device.fbos_config.destroy! # Let's test defaults.
      get :show, format: :json
      expect(response.status).to eq(200)
      {
        device_id: device.id,
        disable_factory_reset: true,
        firmware_input_log: false,
        firmware_output_log: false,
        sequence_body_log: false,
        sequence_complete_log: false,
        sequence_init_log: false,
        arduino_debug_messages: false,
        network_not_found_timer: nil,
        os_auto_update: true,
        firmware_hardware: nil,
      }.to_a.map do |key, value|
        actual = json.fetch(key)
        expected = value
        correct = actual == expected
        friendly_actual_var = actual || "nil or false"
        fail "#{key} should be #{expected} but got #{friendly_actual_var}" unless correct
      end

      { created_at: String, updated_at: String }
        .to_a.map { |key, value| expect(json[key]).to be_kind_of(value) }
    end
  end

  describe "#update" do
    it "raise integer overflow errors" do
      way_too_big = 123456789013333333332345
      sign_in user
      body = { network_not_found_timer: way_too_big }
      put :update, body: body.to_json, params: { format: :json }
      expect(response.status).to eq(422)
      expect(json[:error]).to include("was too big/small")
    end

    it "handles update requests" do
      sign_in user
      body = { firmware_path: "null" }
      body.to_a.map { |key, val| expect(device.fbos_config.send(key)).not_to eq(val) }
      put :update, body: body.to_json, params: { format: :json }
      expect(response.status).to eq(200)
      device.reload
      body.except(:disable_factory_reset).to_a.map do |key, val|
        expect(device.fbos_config.send(key)).to eq(val)
        expect(json[key]).to eq(val)
      end
    end

    it "deprecates disable_factory_reset" do
      sign_in user
      body = { disable_factory_reset: false }
      body.to_a.map { |key, val| expect(device.fbos_config.send(key)).not_to eq(val) }
      put :update, body: body.to_json, params: { format: :json }
      expect(response.status).to eq(200)
      assert json.fetch(:disable_factory_reset)
      refute device.reload.fbos_config.disable_factory_reset
    end

    it "does not enforce row locking if there is only one column change" do
      sign_in user
      expect(device.fbos_config).to be
      body = { updated_at: 2.days.ago, network_not_found_timer: 20 }
      put :update, body: body.to_json, params: { format: :json }
      expect(response.status).to eq(200)
    end

    it "enforces row locking if there is only one column change" do
      sign_in user
      expect(device.fbos_config).to be
      body = {
        updated_at: 2.days.ago,
        network_not_found_timer: 20,
        firmware_hardware: "whatever",
      }
      put :update, body: body.to_json, params: { format: :json }
      expect(response.status).to eq(409)
    end

    it "disallows mass assignment attacks against device_id" do
      sign_in user
      body = { device_id: 99 }
      conf = device.fbos_config
      old_device_id = conf.device_id
      put :update, body: body.to_json, params: { format: :json }
      expect(response.status).to eq(200)
      expect(conf.reload.device_id).to eq(old_device_id)
    end

    it "ignores unknown keys" do
      sign_in user
      body = { blah_blah_blah: true }
      put :update, body: body.to_json, params: { format: :json }
      expect(response.status).to eq(200)
    end
  end

  describe "#delete" do
    it "resets everything to the defaults" do
      sign_in user
      old_conf = device.fbos_config
      old_conf.update(arduino_debug_messages: 23)
      delete :destroy, params: {}
      expect(response.status).to eq(200)
      new_conf = device.reload.fbos_config
      expect(new_conf.arduino_debug_messages).to_not eq(23)
    end
  end
end