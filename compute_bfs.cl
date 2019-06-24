
struct tuple{
	unsigned dvid;
	unsigned end_dvid;
};

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
__global const int* volatile dist_input, // volatile
__global int* restrict dist_output, //
__global int* restrict dist_output_next, //
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
	unsigned accumMin = num_nodes + 1;
	
	for(unsigned ej = start_of_e_chunk; ej < end_of_e_chunk; ej++) // edge loop
	{
		ovid = ovid_of_edge[ej];
		unsigned newDist = dist_input[ovid] + 1;

		if(newDist < accumMin)
			accumMin = newDist;


		if( ej == end_dvid - 1 ){

			if(accumMin < dist_output_next[dvid])
				dist_output[dvid] = accumMin;

			accumMin = num_nodes + 1;
			if(ej < end_of_e_chunk - 1){
				struct tuple t = read_channel_altera(chan0);
				end_dvid = t.end_dvid;
				//update dvid using channel
				//since we don't send zero-degrees, we do not process them.
				dvid = t.dvid;
			}
		}
	}
	//}
} 