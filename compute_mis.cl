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
		if(endIndices[i + 1] <= end_of_e_chunk &&  t.end_dvid != endIndices[i])
			write_channel_altera(chan0, t);
	}
}

__attribute__ ((task))

kernel void compute_PR0(
// vertex info (1 field)
__global const fix16_t* volatile pg_val, // volatile
__global int* restrict isSelected, //

// graph adjacency lists (on 1 direction)
__global const unsigned* restrict ovid_of_edge, // in-edges, other (source) node
__global const unsigned* restrict endIndices, // in-edges, dest node

unsigned const start_of_e_chunk,
unsigned const end_of_e_chunk,
unsigned const dvid__,
unsigned const num_nodes
)
{ 

	//printf("end_of_nodes %d\n", end_of_nodes);
	unsigned ovid; //other vertex id
	unsigned dvid = dvid__; //destination vertex id
	unsigned end_dvid = endIndices[dvid + 1];

	fix16_t min = fix16_from_float(1);

	//end_dvid = read_channel_altera(chan0);
	for(unsigned ej = start_of_e_chunk; ej < end_of_e_chunk; ej++) // edge loop
	{
		ovid = ovid_of_edge[ej];
	fix16_t otherval = pg_val[ovid];


		if(otherval < min)
			min = otherval;

		if( ej == end_dvid - 1){

			unsigned selected;	
			if(pg_val[dvid] < min)
				selected = 1;
			else
				selected = 0;

			isSelected[dvid] = selected;
			min = fix16_from_float(1);
			if(ej < end_of_e_chunk - 1){
				struct tuple t = read_channel_altera(chan0);
				end_dvid = t.end_dvid;
				//update dvid using channel
				//since we don't send zero-degrees, we do not process them.
				dvid = t.dvid;
			}
		}
	}
} 