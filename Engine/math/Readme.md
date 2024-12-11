# Math Library 

> "A fundamental library for game programming"

## Notes:
- opBinary versus opBinaryRight
     - `2 * v` is not the same thing as `v * 2` for our overloads.
          - That is going to 'bite you' if you don't know ahead of time that these are different.
     - It may be useful to include the overloads (which are effectively a copy & paste for any commutative operation).
- opOpAssign is a confusing name, but stare at it for a moment.
	- 'op' is the operation, and then we also want to do an 'opAssign' after it. Basically this just means something like '+=' or '-=' (op is the +, and then do assignemnt (=) after).

### More on opBinaryRight?

Because not every operation in commutative. This is a superpower in the D language to make this very clear when operator overloading. At first I was annoyed by this myself, but then I realized it's much more clear to have two separate functions where order is not commutative. For 3D cross products for instance, this is especially important to make sure the wrong overload does not get called!

## How to compile and run your program

1. You can use simply run `dub test` file to build and run the project.
   - Note: `dub test` by default does a debug build.
   - Don't forget to use [gdb](https://www.youtube.com/watch?v=NWsZrN7gXYg) or [lldb](https://www.youtube.com/watch?v=drzvDkU-H54) if you run into errors!

# Going Further

1. Want to implement more operations? No problem -- go for it!
        - Probably a good place to start is with various intersection functions.
        - At some point we'll implement AABB and OBB collision, but if you want to jump ahead go for it!
