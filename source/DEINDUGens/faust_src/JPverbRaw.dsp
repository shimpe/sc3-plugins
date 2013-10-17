declare name        "JPverbRaw";
declare version     "1.0";
declare author      "Julian Parker";
declare license     "none";
declare copyright   "(c) Julian Parker 2013";

import("oscillator.lib"); 
//import("math.lib"); 
//import("maxmsp.lib"); 
//import("music.lib"); 
//import("reduce.lib"); 
//import("filter.lib"); 
//import("effect.lib"); 
 
allpass_stretched(maxdel,N,a) 	= (+ <: fdelay1a(maxdel,N-1),*(a)) ~ *(-a) : mem, _ : + ;

prime_delays = ffunction(int primes (int),<jprev.h>,"primes");

gi = 1.618;
depth = (44100/SR)*50*hslider("mDepth",0.1,0.0,1.0,0.001);
freq = hslider("mFreq",2.0,0.0,10.0,0.01);
wet = hslider("wet",0.5,0.0,1.0,0.01);
low = hslider("lowX",1.0,0.0,1.0,0.01);
mid = hslider("midX",1.0,0.0,1.0,0.01);
high = hslider("highX",1.0,0.0,1.0,0.01);
early_diff = hslider("earlyDiff", 0.707, 0.0 ,0.99,0.001);
low_cutoff = hslider("lowBand",500,100.0,6000.0,0.1);
high_cutoff = hslider("highBand",2000,1000.0,10000.0,0.1);
size = (44100/SR)*hslider("size",1.0, 0.5,3.0,0.01);
T60 = hslider("t60",1.0,0.1,60.0,0.1);
damping = hslider("damp",0.0,0.0,0.999,0.0001);
calib = 1.7; // Calibration constant given by T60 in seconds when fb = 0.5
total_length = calib*0.1*(size*5/4 -1/4);
fb = 10^(-3/((T60)/(total_length)));


diffuser(angle,g,scale1,scale2) = bus(2) : 
				(bus(4) :> bus(2) <: 
				(rotator(angle) : (fdelay1a(65536, (prime_delays(size*scale1):smooth(0.99)) -1 ),fdelay1a(65536, (prime_delays(size*scale2):smooth(0.999)) -1  ) ) ) ,(g,g) )
				 ~ (-g,-g)
			    :( (mem,mem), bus(2) ) :> bus(2) 
with
{
	rotator(angle) = bus(2) <: (*(c),*(-s),*(s),*(c)) :(+,+) : bus(2)
	with{
		c = cos(angle);
		s = sin(angle);
	};
};

reverb = (	( bus(4) :>  (fdelay4(65536, depth + depth*oscrs(freq) +1 ),fdelay4(65536, depth + depth*oscrc(freq)+ 1 )  ) 
			: par(i,2,smooth(damping)) : diffuser(PI/4,*(early_diff),55,240) :diffuser(PI/4,*(early_diff),215,85):diffuser(PI/4,*(early_diff),115,190):diffuser(PI/4,*(early_diff),175,145)
	
			) ~(
				seq(i,5,diffuser(PI/4,*(0.707),10+30*i,110 + 30*i) ): par(i,2,fdelay4(65536, depth + (-1^i)*depth*oscrc(freq)+(prime_delays(size*(54+150*i)):smooth(0.999)) -1 )) :
				seq(i,5,diffuser(PI/4,*(0.707),125+30*i, 25+30*i) ): par(i,2,fdelay4(65536, depth + (-1^i)*depth*oscrs(freq)+(prime_delays(size*(134-100*i)):smooth(0.999)) -1 )) :
				par(i,2, filterbank(5,(low_cutoff,high_cutoff) ):(_*(high),_*(mid),_*(low)) :> _ ):
				par(i,2,*(fb))
			));

//Alesis Style 2-channel
// with wet control
// process = (_,_) <: ((reverb:par(i,2,_*(wet))), par(i,2,_*(1-wet))) :> (_,_);

// without wet control
process = (_,_) : reverb : (_,_);
