#include <chrono>
#include <iostream>

int main()
{
  using namespace std;
  using namespace chrono;
  cout << format("{0:%F}T{0:%T%z}", zoned_time{current_zone(), floor<microseconds>(system_clock::now())}) << endl;
  return 0;
}
