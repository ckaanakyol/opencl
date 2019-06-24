//TODO: not final version
#pragma OPENCL EXTENSION cl_altera_channels : enable
channel unsigned chan0;
__kernel void producer0(unsigned const start_of_nodes,
unsigned const end_of_nodes,
__global const unsigned* restrict endIndices, // in-edges, dest node)
unsigned const end_of_e_chunk
)
{
	for(unsigned i = start_of_nodes + 1; i < end_of_nodes + 1; i++){
		if(endIndices[i + 1] <= end_of_e_chunk)
			write_channel_altera(chan0, endIndices[i + 1]);
	}
}
__attribute__ ((task))

kernel void compute_PR0(
// vertex info (1 field)
__global const fix16_t* volatile input, // volatile
__global fix16_t* restrict output, //
// graph adjacency lists (on 1 direction)
__global const unsigned* restrict ovid_of_edge, // in-edges, other (source) node
__global const unsigned* restrict endIndices, // in-edges, dest node

unsigned const start_of_e_chunk,
unsigned const end_of_e_chunk,
unsigned const dvid__
)
{ 
	
	unsigned ovid; //other vertex id
	unsigned dvid = dvid__; //destination vertex id	
	unsigned end_dvid = endIndices[dvid+1];
		
	fix16_t toAdd = fix16_from_float(0.0);	
	fix16_t next_val;

	for(unsigned ej = start_of_e_chunk; ej < end_of_e_chunk; ej++) // edge loop
	{
		ovid = ovid_of_edge[ej];
		fix16_t otherval = input[ovid];
		
		toAdd = fix16_add(toAdd, otherval);
			
		
		if( ej == end_dvid || ej == end_dvid - 1){
		
			if (ej == end_dvid - 1) {
				output[dvid] = toAdd;
			
			}
			else{
				
			}
			
			toAdd = fix16_from_float(0.0);
			if(ej < end_of_e_chunk - 1){
				end_dvid = read_channel_altera(chan0);
			}		
			dvid++;	
		}
	}
}