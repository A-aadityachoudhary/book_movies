# CineBook 🎬🍿

A premium, high-concurrency theater ticket reservation engine built with Ruby on Rails. Featuring real-time seat locking via Action Cable WebSockets, race-condition protection using pessimistic database row-level locking, and automated lease expiries via background processing.

## 🚀 Architectural Highlights

* **Real-Time Seating Sync:** Intercepts checkbox interactions instantly via a vanilla JS WebSocket consumer, changing state globally without page refreshes.
* **Race-Condition Defeated:** Enforces strict pessimistic database locking (`FOR UPDATE`) on the database row tier during reservation attempts to prevent duplicate holds.
* **5-Minute Lease Expiries:** Utilizes asynchronous Active Job countdown fuses to automatically evict stale locks and re-open availability to the public pool.
* **Premium Glassmorphic UI:** Wrapped in a sleek, high-contrast theatrical interface styled with dark glass panels and soft backlight leaks using Tailwind CSS.

---

## 🛠️ Tech Stack & Dependencies

* **Framework:** Ruby on Rails (>= 7.1.0)
* **Frontend Asset Pipeline:** Importmaps (Zero-Node compilation footprint)
* **Real-Time Layer:** Action Cable (WebSockets)
* **Background Jobs / Async Queues:** Active Job (backed by Redis / Solid Queue)
* **Database:** PostgreSQL / MySQL (Requires row-level transaction locks)
* **Authorization:** CanCanCan
* **Authentication:** Devise

---

## ⚙️ Core Logic Implementations

### Pessimistic Concurrency Controls
To guarantee that two users clicking the exact same seat within milliseconds cannot both hold it, the application freezes the raw database record until validation checks pass:

```ruby
ActiveRecord::Base.transaction do
  showtime_seat = ShowtimeSeat.lock("FOR UPDATE").find_by(id: showtime_seat_id)
  if showtime_seat.truly_available?
    showtime_seat.update!(status: :locked, locked_by: user, locked_at: Time.current)
    SeatUnlockJob.set(wait: 5.minutes).perform_later(showtime_seat.id, showtime_seat.locked_at)
  end
end
