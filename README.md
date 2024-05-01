# Splash Booking System

This in-house tool allows for bookings to be made for school events. The website is available at: [http://splash-booking.web.app](http://splash-booking.web.app).

# Features
The following features have been implemented in the latest version of the system.

## Identity Management
A reliable identity management system is in place that not only ensures accountability of users for the actions they perform on the app, but also to aid in troubleshooting in production.

- Users log in and use the app through a booking code, provided to them after they fill in an MS Form.
- Each booking code is linked to a Teams ID
- If users forget their booking code, they can submit an MS Form and their booking code will be resent to them via Teams (if they indeed do have one)

## Event Booking
- Users may view events and the number of slots left
- Users may book new events, and the system ensures that:
    - The user only has 1 booking per activity, even if they are in multiple teams
    - Bookings are limited to the number of slots available
    - The team registering for the event has sufficient members
    - None of the members in the team have bookings that overlap with the booked timing
- Users may edit bookings, and the system ensures that the aforementioned constraints are respected

## Team Management
- Users may view their teams, and the activity each team is participating in (if applicable)
- Users may add new teams
- Users may edit team members, and the system ensure that:
    - The first member is the user himself, the team leader
    - The booking codes of the members are valid
    - Team with existing bookings are not allowed to modify their member details
- Users may delete teams, and the system ensures that:
    - If applicable, any booking linked to that team is also deleted (after a confirmation dialog is shown)

## Administrative
- All members who have registered for activities will be sent a reminder via Teams with their booking summaries before the day of the events
- A CSV file can be generated to take a snapshot of the database, using the `splash_administrator` tool (a separate codebase)
- Issues are reported via another MS Form, where users can also submit screenshots
- Cloud Logging from Google Cloud Platform (GCP) is used by the app to gather logs for troubleshooting

# Tech Stack
This is the software stack used by the app:
| Purpose  | Software |
| ------------- | ------------- |
| Database  | Cloud Firestore  |
| Hosting, CDN  | Firebase Hosting  |
| Frontend  | Flutter  |
| Logging  | GCP Cloud Logging  |
| Automations/Workflows  | MS Power Automate  |