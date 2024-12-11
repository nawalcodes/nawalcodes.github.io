// @file vec2.d
/// This file defines a 2D vector library in D, including types, operations, and utility functions.
/// It supports both integral and floating-point vector types, and provides features like
/// vector arithmetic, magnitude, normalization, and more.
module vec2;

import std.math;
import std.stdio;
import std.traits;

// --- Type Aliases ---
/// Vec2f: Alias for Vec2!float, commonly used for floating-point vectors.
/// Vec2i: Alias for Vec2!int, commonly used for integer vectors.
alias Vec2f = Vec2!float;
alias Vec2i = Vec2!int;

// --- Struct Vec2 ---
/// Template struct for representing a 2D vector. Supports integral and floating-point types.
struct Vec2(T) // Template Constraint esnures only integral types
// are supplied as template arguments during creation.
if (__traits(isIntegral, T) || __traits(isFloating, T))
{
	// --- Internal Data ---
	/// The vector is represented using a union to allow access through different notations.
	union
	{
		struct
		{
			T x = 0, y = 0;
		} // Default cartesian coordinates
		struct
		{
			T s, t;
		} // Alternative notation for texture coordinates
		struct
		{
			T i, j;
		} // Alternative notation for indexing
		struct
		{
			T[2] elem;
		} // Array representation for iteration and indexing
	}

	// --- Array-Like Access ---
	/// Provides access to vector elements via an index.
	ref T opIndex(size_t index)
	{
		return elem[index];
	}

	// --- Unary Operators ---
	/// Negates the vector or performs pre/post increment/decrement.
	ref typeof(this) opUnary(string op)()
	{
		// TODO:
		if (op == "-")
		{
			x = -x;
			y = -y;
		}

		else if (op == "--")
		{
			x -= 1;
			y -= 1;
		}

		else if (op == "++")
		{
			x += 1;
			y += 1;
		}

		return this;
	}

	// --- Binary Operators ---
	/// Performs addition or subtraction with another vector.
	ref typeof(this) opBinary(string op)(typeof(this) rhs)
	{
		if (op == "+")
		{
			x += rhs.x;
			y += rhs.y;
		}
		else if (op == "-")
		{
			x -= rhs.x;
			y -= rhs.y;
		}
		return this;
	}

	/// Performs scalar multiplication or division.
	ref typeof(this) opBinary(string op)(double rhs)
	{
		if (op == "*")
		{
			x *= rhs;
			y *= rhs;
		}
		else if (op == "/")
		{
			x /= rhs;
			y /= rhs;
		}
		return this;
	}

	// --- Compound Assignment Operators ---
	/// Combines assignment with addition or subtraction.
	ref typeof(this) opOpAssign(string op)(typeof(this) rhs)
	{
		if (op == "+")
		{
			this = this + rhs;
		}
		else if (op == "-")
		{
			this = this - rhs;
		}
		return this;
	}

	/// Combines assignment with scalar multiplication or division.
	ref typeof(this) opOpAssign(string op)(double rhs)
	{
		if (op == "*")
		{
			this = this * rhs;
		}
		else if (op == "/")
		{
			this = this / rhs;
		}
		return this;
	}

	// --- Magnitude ---
	/// Calculates the magnitude (length) of the vector.
	double Magnitude()
	{
		return sqrt(cast(double)(x * x + y * y));
	}

	// --- Normalization ---
	/// Converts the vector to a unit vector. Only supports floating-point types.
	/// Note: Returns unnormlized vector if length is 0.
	typeof(this) Normalize()
	{
		// Cache value of magnitude to maybe save some time
		static if (__traits(isFloating, T))
		{
			auto mag = this.Magnitude();
			if (mag == 0)
				return this;
			return this / mag;
		}
		else
		{
			assert(0, "Can only normalize floating point values. Normalize Vec2f, and then cast to Vec2i");
		}
	}

	// --- Slope ---
	/// Calculates the slope of the vector. Returns 0.0 if the x component is zero.
	double GetSlope()
	{
		if (isClose(x, 0.0f))
		{
			return 0.0f;
		}
		return cast(double) y / cast(double) x;
	}

	/// --- Normal Vector ---
	/// Returns the normal vector (not normalized). If zero vector, returns zero vector.
	typeof(this) GetNormal()
	{
		typeof(this) result;
		// If we define dx = x2 - x1 and dy = y2 - y1, then the normals are (-dy, dx) and (dy, -dx).
		result.x = -y;
		result.y = x;

		// Check if this is a zero vector
		if (x == 0 && y == 0)
		{
			result.x = 0;
			result.y = 0;
		}

		return result;
	}
}

// --- Utility Functions ---

/// Computes the dot product of two vectors.
double Dot(T)(T v1, T v2)
{
	return cast(double)(v1.x * v2.x + v1.y * v2.y);
}

/// Reflects a vector across a given normal vector.
// *Hint* Normalizing the vectors makes this easier
// Helpful chapter: https://immersivemath.com/ila/ch03_dotproduct/ch03.html
// Another pragmatic resource: https://www.sunshine2k.de/articles/coding/vectorreflection/vectorreflection.html
// We used this formula for my implementation at the top:
// https://www.contemporarycalculus.com/dh/Calculus_all/CC11_7_VectorReflections.pdf
T Reflect(T)(T v, T n)
{
	T result;
	// normalize normal vector
	auto norm_n = n.Normalize;

	// reflect [v - 2 * (v · n) * n]
	result = v - norm_n * (2 * Dot(v, norm_n));

	return result;
}

/// Projects vector u onto vector v and returns the new vector.
T Project(T)(T u, T v)
{
	T result;
	// (u.v)/(v.v) * v
	double prod = Dot(u, v) / Dot(v, v);
	result = v * prod;
	return result;
}

// --- Type Aliases for Points ---
/// Alias Point2 for Vec2 to provide semantic clarity.
alias Point2f = Vec2f;
alias Point2i = Vec2i;

// --- Distance ---
/// Calculates the Euclidean distance between two points given their coordinates.
double Distance(double x1, double y1, double x2, double y2)
{
	// TODO:
	return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
}

/// Overload of Distance for two Vec2 objects.
double Distance(T)(T p1, T p2)
{
	double dx = cast(double)(p1.x - p2.x);
	double dy = cast(double)(p1.y - p2.y);
	return sqrt(dx * dx + dy * dy);
}
// --- Angle Conversions ---
/// Converts degrees to radians.
float DegreesToRadians(float degree)
{
	return degree * PI / 180;
}

/// Converts radians to degrees.
float RadiansToDegrees(float rad)
{
	return rad * 180 / PI;
}

// --- Unit Tests ---
// Various unit tests to verify the functionality of the vector library.
// Projection unit test
unittest
{
	Vec2f u = Vec2f(4, 3);
	Vec2f v = Vec2f(2, 8);

	// Project vector u onto vector v
	auto result = Project(u, v);

	assert(isClose(result.x, (16.0 / 17.0)) && isClose(result.y, (64.0 / 17.0)), "Expected ~.94117 and 3.7647");
}

// Compute the distance between two points 
unittest
{
	// Manual point entry
	assert(Distance(3, 5, 6, 9) == 5, "5 expected");
	// Templated function
	assert(Distance(Vec2i(3, 5), Vec2i(6, 9)) == 5, "5 expected");
	assert(isClose(Distance(Vec2f(3.0f, 5.0f), Vec2f(6.0f, 9.0f)), 5.0f), "5.0f expected");
	// Testing alias
	assert(Distance(Point2i(3, 5), Point2i(6, 9)) == 5, "5 expected");
	assert(isClose(Distance(Point2f(3.0f, 5.0f), Point2f(6.0f, 9.0f)), 5.0f), "5.0f expected");
}

// Degrees and radians conversions
unittest
{
	float initial = 47.0f;
	float rads = DegreesToRadians(initial);
	float result = RadiansToDegrees(rads);

	assert(isClose(result, 47.0f), "Expected 47.0f");
}

// Test for instantiating different types
unittest
{
	auto myVec1 = Vec2!float();
	auto myVec2 = Vec2!double();
	auto myVec4 = Vec2!int();
	auto myVec6 = Vec2!long();

	//  Note: Why are these types not available?
	//        In short, we don't need to support them.
	//        For our vector library otherwise, we need
	//        signed types.
	//		auto myVec3 = Vec2!char();
	// 		auto myVec5 = Vec2!short();
	// 		auto myVec7 = Vec2!ushort();
	// 		auto myVec8 = Vec2!uint();
	//		auto myVec9 = Vec2!ulong();
}

// Test alias of type
unittest
{
	auto myVec1 = Vec2f();
	auto myVec2 = Vec2i();
}

// Test constructors
unittest
{
	Vec2!float test0 = Vec2!float(7.4f, 9.6f);
	Vec2f test = Vec2f();
	Vec2i test2 = Vec2i(1, 2);
}

// Test size of the data type
unittest
{
	static assert(float.sizeof == 4, "4 for size of float on this architecture");
	assert(Vec2f.sizeof == float.sizeof * 2, "8 expected");
}

// Test data layout within struct
unittest
{
	auto myVec1 = Vec2f();

	assert((myVec1.x == myVec1.s) && (myVec1.i == myVec1[0]), "");
	assert((myVec1.y == myVec1.t) && (myVec1.j == myVec1[1]), "");
}

// Negation test
unittest
{
	Vec2i v1;
	v1.x = 5;
	v1.y = 6;
	v1 = -v1;

	assert(v1.x == -5, "-5 expected");
	assert(v1.y == -6, "-6 expected");
}

// Test opUnary for ++ and --
// This tests both pre and post-increment and
// pre and post-decrement
unittest
{
	Vec2i v1;
	v1.x = 2;
	v1.y = 3;

	v1++;
	assert(v1.x == 3, "3 expected");
	assert(v1.y == 4, "4 expected");
	v1--;
	assert(v1.x == 2, "2 expected");
	assert(v1.y == 3, "3 expected");
	++v1;
	assert(v1.x == 3, "3 expected");
	assert(v1.y == 4, "4 expected");
	--v1;
	assert(v1.x == 2, "2 expected");
	assert(v1.y == 3, "3 expected");
}

// Test opBinary for addition and subtraction of vectors
unittest
{
	Vec2i v1;
	Vec2i v2;

	v1.x = 5;
	v1.y = 7;
	v2.x = 5;
	v2.y = 7;

	v1 = v1 + v2;
	assert(v1.x == 10 && v1.y == 14, "10 and 14 expected");
	assert(v2.x == 5 && v2.y == 7, "5 and 7 expected");
	v1 = v1 - v2;
	assert(v1.x == 5 && v1.y == 7, "5 and 7 expected");
	v1 = v2 - v1;
	assert(v1.x == 0 && v1.y == 0, "0 and 0 expected");
}

// Test opBinary with opUnary operation
unittest
{
	Vec2i v1;
	Vec2i v2;

	v1.x = 5;
	v1.y = 7;
	v2.x = 5;
	v2.y = 7;

	v1 = -v1 + -v2;

	assert(v1.x == -10 && v1.y == -14, "0 and 0 expected");
}

// Test opBinary with * and / for scalar multiplication and division
unittest
{
	Vec2f v1;
	double scalar = 2.0;

	v1.x = 5;
	v1.y = 7;

	v1 = v1 * scalar;

	assert(v1.x == 10 && v1.y == 14, "10 and 14 expected");
}

// Test opBinary with * and / for scalar multiplication and division
unittest
{
	Vec2f v1 = Vec2f(1.5f, 2.5f);
	Vec2f result = v1 * 2.0f;

	assert(result.x == 3.0f && result.y == 5.0f, "3.0f and 5.0f expected");
}

// Test opOpAssign for assignment and an operation
unittest
{
	Vec2f v1 = Vec2f(1.0, 1.0);
	Vec2f v2 = Vec2f(2.0f, 2.0);

	v1 += v2;
	v1 -= v2;

	v1 *= 5;
	v1 /= 5;

	v1 += v2;
	assert(v1.x == 3.0 && v1.y == 3.0, "3 and 3 expected");

	v1 *= 3;

	assert(v1.x == 9.0 && v1.y == 9.0, "9 and 9 expected");
}

// Test magnitude operation
unittest
{
	Vec2f v1;
	v1.x = 3.0f;
	v1.y = 4.0f;

	assert(isClose(v1.Magnitude(), 5.0), "Expected 5.0 or close");
}

// Test if normalized function is working
unittest
{
	Vec2f v1;
	v1.x = 3.0f;
	v1.y = 4.0f;

	v1.Normalize();

	assert(isClose(v1.Magnitude(), 1.0, 1e-2, 1e-5), "Expected 1.0 or close");
}

// Test if normalized function is working with negatives
unittest
{
	Vec2f v1 = Vec2f(-3.0f, -4.0f);

	v1.Normalize();

	assert(isClose(v1.Magnitude(), 1.0, 1e-2, 1e-5), "Expected 1.0 or close");
}

// Take the dot product of two vectors
unittest
{
	Vec2i v1;
	Vec2i v2;

	v1.x = 0;
	v1.y = 1;
	v2.x = 1;
	v2.y = 0;

	assert(v1.Dot(v2) == 0, "Expected 0.0 or close");

	Vec2f v3;
	Vec2f v4;

	v3.x = -1;
	v3.y = 0;
	v4.x = 1;
	v4.y = 0;
	assert(v3.Dot(v4) == -1, "Expected -1 or close");
}

// Retrieve the normal
unittest
{
	Vec2f v1;
	v1.x = 8;
	v1.y = 4;

	Vec2f normal = v1.GetNormal();
	writeln(normal);
	assert(normal.x == -4.0f && normal.y == 8.0f, "");
}

// Take the dot product of two vectors
unittest
{
	Vec2f v1;
	v1.x = 8;
	v1.y = 4;

	assert(v1.GetSlope() == 0.5, "Expected 0.5 or close");
	v1.x = 4;
	v1.y = 8;

	assert(v1.GetSlope() == 2.0, "Expected 0.5 or close");
}

// GetSlope test
unittest
{
	Vec2f v1 = Vec2f(5.0f, 1.0f);
	Vec2f v2 = Vec2f(0.0, 10.0f);

	assert(v1.GetSlope() == 0.2f, "0.2f expected");
	assert(v2.GetSlope() == 0.0f, "0.0f expected -- infinite slope effectively");
}

// Reflection Test
unittest
{
	// Draw some line along x-axis
	Vec2f v1 = Vec2f(2.0, 1.0f);
	// Creating an incoming vector
	Vec2f i = Vec2f(-1.0f, -1.0f);

	auto reflectedVector = Reflect(i, v1.GetNormal());

	writeln("reflectedVector", reflectedVector);

}
