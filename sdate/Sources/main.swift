// Copyright 2024 Frank Stutz.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

// Don't really need the struct/function (mainly here for portability to other apps)
struct LOGT {
    func fmt() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.'MICROS'xx"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let now = Date()
        let dateParts = Calendar.current.dateComponents([.nanosecond], from: now)
        let microSeconds = Int((Double(dateParts.nanosecond!) / 1000).rounded(.toNearestOrEven))
        let microSecPart = String(microSeconds).padding(toLength: 6, withPad: "0", startingAt: 0)
        // Format the date and add in the microseconds
        var timestamp = dateFormatter.string(from: now)
        timestamp = timestamp.replacingOccurrences(of: "MICROS", with: microSecPart)

        return timestamp
    }
}
print(LOGT().fmt())

