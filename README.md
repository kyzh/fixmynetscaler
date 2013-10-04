HALP!
=====
My netscaler is set to use least connection but it remain on round-robin forever

The problem
==========
Netscaler have a "Feature" called "Slow start".
It doesn't actually help _if_ you have a slow start, it makes things worse
The problem it tries to solve is burst connection.
They implemented this because when a bunch of services just started, you are fine with round-robin, no matter what actual policy you want right (right?).
They make you use round-robin, until you are out of this "starting point", where there is enough connection to start using what policy you set, like least connection balancing for example

The real problem
=============
The real problem is this is hardly documented (see there) [http://support.citrix.com/article/CTX108886]

The solution
==========
Hit the service tcp port enough time to be in the "warm" state

How?
====
See the code for the formula
