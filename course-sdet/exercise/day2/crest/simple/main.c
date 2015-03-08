#include "crest.h"

int f(int x);
int f_inverse(int x);

int main()
{
	int x, y;

	// declare x as symbolic variable
	CREST_int(x);

	y = f(x);

	printf ("> f(%d)  = %d\n", x,  y);
	printf ("> f'(%d) = %d\n", y,  f_inverse(y));
		 		  
	// assert: x == f'(f(x))
	if(x != f_inverse(f(x)))
	{
		puts ("+++ x != f'(f(x))");
		return 1;
	}
	return 0;
}

int f(int x) {
	switch (x) {
		case 0: 
		case 1: 
		case 2: 
		case 3: 
		case 4: 
			return x + 10;
		default:
			return x + 100;
	}
}

int f_inverse(int x) {
	switch (x) {
		case 10:
		case 11: 
		case 12: 
		case 13: 
		case 14: 
			return x - 10;
		default:
			return x - 100;
	}
}


