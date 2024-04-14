# Splash Booking System

This in-house tool allows for bookings to be made for events within ACS(I). The website is available at: [http://splash-booking.web.app](http://splash-booking.web.app).

# Features
The following features have been implemented in the latest version of the system.
## Identity
- Users are identified by the first segment of their MS Teams IDs.

## Event Booking
- Users may view events and the number of slots left
- Users may book new events, and the system ensures that:
    - The user only has 1 slot per activity
    - Bookings are limited to the number of slots available
    - The team registering for the event has sufficient members
- Users may edit bookings, and the system ensures that the aforementioned constraints are respected

## Team Management
- Users may view their teams, and the activity each team is participating in (if applicable)
- Users may add new teams
- Users may edit team members, and the system ensure that:
    - The first member is the user himself, the team leader

# Pipeline
The following features will be implemented soon.

## Team Locking
- Currently, the system allows team sizes to be modified (through the addition new members or removal of old ones) even if the team already has a booking. This can create unexpected data inconsistencies, and will be remedied by only allowing member names to be edited for teams with existing bookings.