import { createConsumer } from "@rails/actioncable"

const LOCK_DURATION_MS = 60 * 1000; // must match server's 1.minute
const seatTimers = {};

function paintSeat(wrapper, checkbox, status, lockedById, currentUserId) {
  if (!wrapper || !checkbox) return;
  const base = "w-10 h-10 border rounded-xl flex items-center justify-center font-bold text-xs shadow-md transition-all select-none duration-150";
  const canBook = checkbox.dataset.canBook !== "false";

  if (status === "booked") {
    checkbox.checked = false;
    checkbox.disabled = true;
    wrapper.className = `${base} bg-stone-900/50 border-white/5 text-white/20 cursor-not-allowed line-through`;
    wrapper.innerHTML = wrapper.dataset.seatLabel || "X";

  } else if (status === "locked") {
    if (String(lockedById) !== String(currentUserId)) {
      checkbox.checked = false;
      checkbox.disabled = true;
      wrapper.className = `${base} bg-stone-900/50 border-white/5 text-orange-300/40 cursor-not-allowed`;
      wrapper.innerHTML = "🔒";
    } else {
      checkbox.disabled = !canBook;
      checkbox.checked = true;
      wrapper.className = `${base} bg-white text-stone-950 border-white scale-90 shadow-black/20 cursor-pointer`;
      wrapper.innerHTML = wrapper.dataset.seatLabel;
    }

  } else if (status === "available") {
    checkbox.checked = false;
    checkbox.disabled = !canBook;
    wrapper.className = canBook
      ? `${base} bg-white/10 border-white/20 text-white cursor-pointer hover:border-white hover:bg-white/20 peer-checked:bg-white peer-checked:border-white peer-checked:text-stone-950 peer-checked:scale-90 shadow-black/20`
      : `${base} bg-white/10 border-white/20 text-white/50 cursor-not-allowed`;
    wrapper.innerHTML = wrapper.dataset.seatLabel;
  }
}

// Schedule a client-side countdown that releases the seat UI after the
// lock expires. Every connected browser does this independently — no
// cross-process ActionCable broadcast from Sidekiq needed for the unlock.
function scheduleClientRelease(seatId, lockedAt, wrapper, checkbox, currentUserId) {
  clearTimeout(seatTimers[seatId]);

  const remaining = LOCK_DURATION_MS - (Date.now() - new Date(lockedAt).getTime());

  if (remaining <= 0) {
    // Lock already expired (e.g. page loaded mid-lock that has since passed)
    paintSeat(wrapper, checkbox, "available", null, currentUserId);
    return;
  }

  seatTimers[seatId] = setTimeout(() => {
    paintSeat(wrapper, checkbox, "available", null, currentUserId);
    delete seatTimers[seatId];
  }, remaining);
}

function clearSeatTimer(seatId) {
  clearTimeout(seatTimers[seatId]);
  delete seatTimers[seatId];
}

document.addEventListener("turbo:load", () => {
  const seatContainer = document.getElementById("seating-chart-deck");
  if (!seatContainer) return;

  const showtimeId = seatContainer.dataset.showtimeId;
  const currentUserId = seatContainer.dataset.currentUserId; // keep as string
  const consumer = createConsumer();

  // On page load, set timers for any seats that are already locked
  // (handles users who arrive mid-lock)
  seatContainer.querySelectorAll('[data-locked-at]').forEach((wrapper) => {
    const lockedAt = wrapper.dataset.lockedAt;
    if (!lockedAt) return;
    const seatId = wrapper.id.replace("seat_wrapper_", "");
    const checkbox = document.getElementById(`checkbox_${seatId}`);
    scheduleClientRelease(seatId, lockedAt, wrapper, checkbox, currentUserId);
  });

  const seatingChannel = consumer.subscriptions.create(
    { channel: "SeatingChannel", showtime_id: showtimeId },
    {
      received(data) {
        const seatId = String(data.showtime_seat_id);
        const wrapper = document.getElementById(`seat_wrapper_${seatId}`);
        const checkbox = document.getElementById(`checkbox_${seatId}`);
        if (!wrapper || !checkbox) return;

        if (data.action === "seat_updated" && data.status) {
          if (data.status === "locked") {
            paintSeat(wrapper, checkbox, "locked", data.locked_by_id, currentUserId);
            // Every browser starts its own countdown from locked_at
            if (data.locked_at) {
              scheduleClientRelease(seatId, data.locked_at, wrapper, checkbox, currentUserId);
            }
          } else {
            // "available" or "booked" — cancel any pending countdown
            clearSeatTimer(seatId);
            paintSeat(wrapper, checkbox, data.status, data.locked_by_id, currentUserId);
          }

        } else if (data.action === "lock_failed" && String(data.user_id) === String(currentUserId)) {
          clearSeatTimer(seatId);
          paintSeat(wrapper, checkbox, "locked", "__other__", currentUserId);
          alert("Sorry! Another user grabbed this seat just before your click registered.");
        }
      },

      toggleSeat(showtimeSeatId, isSelected) {
        this.perform("toggle_seat", { showtime_seat_id: showtimeSeatId, selected: isSelected });
      }
    }
  );

  seatContainer.addEventListener("change", (event) => {
    if (event.target.matches("input[name='seat_ids[]']")) {
      const checkbox = event.target;
      seatingChannel.toggleSeat(checkbox.value, checkbox.checked);
    }
  });

  // Clean up timers when navigating away (Turbo)
  document.addEventListener("turbo:before-visit", () => {
    Object.keys(seatTimers).forEach(clearSeatTimer);
  }, { once: true });
});