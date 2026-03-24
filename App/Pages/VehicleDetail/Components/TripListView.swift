import SwiftUI

struct TripListView: View {
  @StateObject private var vehiclesStore: VehiclesStore = .shared

  private var trips: [TripData] {
    vehiclesStore.vehicleDetailVehicle?.tripList ?? []
  }

  var body: some View {
    VStack(spacing: 12) {
      if trips.isEmpty {
        VStack(spacing: 8) {
          Image("img_trips_empty")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 240)
          Text("暂无行程")
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "0x333333"))
        }
        .frame(height: 240)
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
      } else {
        LazyVStack(spacing: 12) {
          ForEach(trips, id: \.id) { trip in
            TripCell(trip: trip)
              .onAppear {
                Task {
                  await vehiclesStore.loadMoreVehicleDetailTripsIfNeeded(currentTripId: trip.id)
                }
              }
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 180)
    .taskOnce {
      if trips.isEmpty {
        await vehiclesStore.refreshVehicleDetailTrips()
      }
    }
  }
}
