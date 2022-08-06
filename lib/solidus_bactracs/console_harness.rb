module SolidusBactracs
  class ConsoleHarness
    attr_reader :runner, :syncer, :sync, :shipments, :shipments_elegible

    attr_accessor :cursor, :batch

    def initialize
      @runner = SolidusBactracs::Api::RequestRunner.new
      @syncer = SolidusBactracs::Api::BatchSyncer.from_config
      @sync = SolidusBactracs::Api::ScheduleShipmentSyncsJob.new
      @shipments = SolidusBactracs::Api::ScheduleShipmentSyncsJob.new.query_shipments
      @shipments_elegible = SolidusBactracs::Api::ScheduleShipmentSyncsJob.new.all_elegible_shipments
      @cursor = 0
      @batch = 4
    end

    def refresh
      @shipments = SolidusBactracs::Api::ScheduleShipmentSyncsJob.new.query_shipments
    end

    def shipment(id)
      @shipments.find_by(id: id)
    end

    def shipment_number(ship_number)
      @shipments.find_by(number: ship_number)
    end

    def serialize(shipment)
      # SolidusShipstation::Api::ApplianceShipmentSerializer.new(shipment)
      @syncer.client.shipment_serializer.call(shipment, @runner.authenticate!)
    end

    def try_one
      puts "trying shipment #{(shipment = @shipments[@cursor]).id}"
      # resp = @runner.call(:post, '/orders/createorders', [serialize(shipment)])
      resp = @runner.authenticated_call(shipment: shipment, serializer: @syncer.client.shipment_serializer)
      if resp
        @cursor += 1
        return resp
      end
    ensure
      puts resp
    end

    def try_batch(batch_size=nil)
      b = [batch_size.to_i, @batch].max
      b.times do
        break unless try_one
      end
    end
  end
end
