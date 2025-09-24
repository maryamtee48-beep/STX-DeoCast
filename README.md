
### STX-DeoCast - Decentralized Video Streaming Platform – Smart Contract



**Description**:
This smart contract enables a decentralized video streaming platform with functionalities for content creators, premium subscribers, revenue sharing, and platform governance.

---

### 🚀 Features

* **Video Management**

  * Upload videos with title, description, price, and content hash
  * Track views, revenue, and activation status per video

* **User Payments & Subscriptions**

  * Users can purchase videos directly from creators
  * Premium subscriptions available (time-based access)

* **Creator Registration**

  * Open registration for content creators
  * Creators receive direct STX payments from users

* **Admin Controls**

  * Platform fee adjustment (max 10%)
  * Contract pause/resume toggle
  * Add new administrators

* **Revenue Tracking**

  * Creator-level and platform-level revenue maps
  * Revenue auto-updated upon purchases

* **Governance (Proposal System)**

  * Support for submitting, voting, and executing proposals

---

### 🛡️ Access Control

* `contract-owner`: Auto-assigned on deployment
* `administrators`: Can update platform fee, pause/unpause contract, add new admins
* `content-creators`: Must register before uploading content
* `premium-subscribers`: Tracked via block height–based expiration

---

### 📚 Key Functions

| Function                | Access    | Purpose                                      |
| ----------------------- | --------- | -------------------------------------------- |
| `register-as-creator`   | Public    | Allows users to register as creators         |
| `upload-video`          | Creators  | Upload a new video with metadata             |
| `purchase-video`        | Public    | Purchase access to a video                   |
| `subscribe-premium`     | Public    | Subscribe to premium access (duration-based) |
| `set-platform-fee`      | Admin     | Adjust the platform's revenue fee            |
| `toggle-contract-pause` | Admin     | Pause/unpause platform functionality         |
| `add-administrator`     | Admin     | Grant admin privileges to another user       |
| `get-video-details`     | Read-only | Fetch metadata and stats for a video         |
| `is-premium-subscriber` | Read-only | Check if user has an active premium sub      |

---

### 💰 Revenue & Fees

* **Platform Fee**: Adjustable percentage (max 10%) from video transactions
* **Creator Revenue**: Automatically updated on purchases
* **Platform Revenue**: Tracked separately

---

### 📌 Deployment Notes

* Initializes `contract-owner` as the first admin
* Sets up empty mappings for admins, creators, videos, and subscriptions

---

### 📄 License

This smart contract is open-source and may be used under the MIT License.

---
