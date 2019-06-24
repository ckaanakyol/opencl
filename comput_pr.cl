struct tuple{
	unsigned dvid;
	unsigned end_dvid;
};
//channel unsigned chan1;
#pragma OPENCL EXTENSION cl_altera_channels : enable
channel struct tuple chan0;
__kernel void producer0(unsigned const start_of_nodes,
unsigned const end_of_nodes,
__global const unsigned* restrict endIndices, // in-edges, dest node)
unsigned const end_of_e_chunk
)
{
	for(unsigned i = start_of_nodes + 1; i < end_of_nodes + 1; i++){
		struct tuple t;
		t.dvid = i;
		t.end_dvid = endIndices[i + 1];

		//writes tuples to the channel, unless it is zero-degree.
		//vtx is zero-degree, if its end_dvid == end_dvid of previous.
		if(endIndices[i + 1] <= end_of_e_chunk &&  t.end_dvid != endIndices[i]){
			write_channel_altera(chan0, t);
		}
	}
}
__attribute__ ((task))

kernel void compute_PR0(
// vertex info (1 field)
__global const fix16_t* volatile pg_val, // volatile
__global const fix16_t* volatile __pg_val, // volatile
__global fix16_t* restrict pg_val_next, //
__global fix16_t* restrict __pg_val_next, //

__global const fix16_t* restrict pg_division,

// graph adjacency lists (on 1 direction)
__global const unsigned* restrict ovid_of_edge, // in-edges, other (source) node
__global const unsigned* restrict endIndices, // in-edges, dest node

fix16_t const dampener, 
fix16_t const dampen_av,

unsigned const start_of_e_chunk,
unsigned const end_of_e_chunk,
unsigned const dvid__,
unsigned const num_nodes
)
{ 
	
	unsigned ovid; //other vertex id
	unsigned dvid = dvid__; //destination vertex id	
	unsigned end_dvid = endIndices[dvid+1];
		
	fix16_t toAdd = fix16_from_float(0.0);	
	fix16_t next_val;
	fix16_t div;

	for(unsigned ej = start_of_e_chunk; ej < end_of_e_chunk; ej++) // edge loop
	{
		ovid = ovid_of_edge[ej];

		div = pg_division[dvid];		
		toAdd = fix16_add(toAdd, pg_val[ovid]);
		
		if( ej == end_dvid - 1){
			next_val = fix16_mul( fix16_add(dampen_av, fix16_mul(dampener, toAdd)), div);
			pg_val_next[dvid] = next_val;
			__pg_val_next[dvid] = __pg_val[dvid];

			toAdd = fix16_from_float(0.0);	
			if(ej < end_of_e_chunk - 1){
				struct tuple t = read_channel_altera(chan0);
				end_dvid = t.end_dvid;
				dvid = t.dvid;
			}				
		}
	}
} 