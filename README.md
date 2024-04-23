# Splash Booking System

This in-house tool allows for bookings to be made for events within ACS(I). The website is available at: [http://splash-booking.web.app](http://splash-booking.web.app).

# Features
The following features have been implemented in the latest version of the system.

## Identity
- Users are identified by booking codes sent to them via MS Teams DM after they fill out the form.

## Event Booking
- Users may view events and the number of slots left
- Users may book new events, and the system ensures that:
    - The user only has 1 slot per activity
    - Bookings are limited to the number of slots available
    - The team registering for the event has sufficient members
    - None of the members in the team have bookings that overlap with the current one
- Users may edit bookings, and the system ensures that the aforementioned constraints are respected

## Team Management
- Users may view their teams, and the activity each team is participating in (if applicable)
- Users may add new teams
- Users may edit team members, and the system ensure that:
    - The first member is the user himself, the team leader
    - The members also have booking codes (obtained via the MS Form)
    - Team with existing bookings do not add or remove members
- Users may delete teams, and the system ensures that:
    - If applicable, any booking linked to that team is also deleted (after a confirmation dialog is shown)

## Administrative
- All members who have registered for activities will be sent a reminder via Teams with their booking summaries
- A CSV file can be generated to take a snapshot of the database, using the `splash_administrator` tool (a separate codebase)