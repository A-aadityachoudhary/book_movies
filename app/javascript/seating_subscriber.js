import { createConsumer } from "@rails/actioncable"

document.addEventListener("turbo:load", () => {
  const seatContainer = document.getElementById("seating-chart-deck");
  if (!seatContainer) return; // Exit if we aren't on the seating map page

  const showtimeId = seatContainer.dataset.showtimeId;
  const currentUserId = parseInt(seatContainer.dataset.currentUserId, 10);
  const consumer = createConsumer();

  // Create real-time subscription stream
  const seatingChannel = consumer.subscriptions.create(
    { channel: "SeatingChannel", showtime_id: showtimeId },
    {
      connected() {
        console.log(`Connected to seating deck for showtime #${showtimeId}`);
      },

      disconnected() {
        console.log("Disconnected from seating stream.");
      },

      received(data) {
        const seatId = data.showtime_seat_id;
        const seatElement = document.getElementById(`seat_wrapper_${seatId}`);
        const checkbox = document.getElementById(`checkbox_${seatId}`);
        
        if (!seatElement || !checkbox) return;

        if (data.action === "seat_updated") {
          if (data.status === "locked") {
            if (data.locked_by_id !== currentUserId) {
              // Seat locked by someone else: freeze it
              checkbox.disabled = true;
              checkbox.checked = false; // Force uncheck if they had it open
              seatElement.className = "w-10 h-10 border rounded-xl flex items-center justify-center font-bold text-xs shadow-md transition-all select-none duration-150 bg-stone-900/50 border-white/5 text-orange-300/40 cursor-not-allowed";
              seatElement.innerHTML = "🔒";
            }
          } else if (data.status === "available") {
            // Unlocked or expired
            checkbox.disabled = false;
            checkbox.checked = false;
            seatElement.className = "w-10 h-10 border rounded-xl flex items-center justify-center font-bold text-xs shadow-md transition-all select-none duration-150 bg-white/10 border-white/20 text-white cursor-pointer hover:border-white hover:bg-white/20 peer-checked:bg-white peer-checked:border-white peer-checked:text-stone-950 peer-checked:scale-90 shadow-black/20";
            seatElement.innerHTML = seatElement.dataset.seatLabel;
          }
        } else if (data.action === "lock_failed" && data.user_id === currentUserId) {
          // This client lost the millisecond race condition
          checkbox.checked = false;
          checkbox.disabled = true;
          seatElement.className = "w-10 h-10 border rounded-xl flex items-center justify-center font-bold text-xs shadow-md transition-all select-none duration-150 bg-stone-900/50 border-white/5 text-orange-300/40 cursor-not-allowed";
          seatElement.innerHTML = "🔒";
          alert("Sorry! Another user grabbed this seat right before you click it.");
        }
      },

      toggleSeat(showtimeSeatId, isSelected) {
        this.perform("toggle_seat", { showtime_seat_id: showtimeSeatId, selected: isSelected });
      }
    }
  );

  // Monitor clicks on the seating checkboxes
  seatContainer.addEventListener("change", (event) => {
    if (event.target.matches("input[name='seat_ids[]']")) {
      const checkbox = event.target;
      const showtimeSeatId = checkbox.value;
      const isSelected = checkbox.checked;

      // Direct message via WebSocket to hold or free the seat
      seatingChannel.toggleSeat(showtimeSeatId, isSelected);
    }
  });
});