#include <chrono>
#include <iostream>

int main()
{
  using namespace std;
  using namespace chrono;

  auto utc_now = floor<microseconds>(system_clock::now());
  auto micro = zoned_time{current_zone(), utc_now};
  cout << format("{0:%F}T{0:%T%z}", micro) << endl;
  return 0;
}


