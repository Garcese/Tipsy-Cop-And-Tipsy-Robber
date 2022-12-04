# cops_and_robbers
 Programming work dedicated to the Tipsy Cop and Tipsy Robber research project - a generalization of the regular Cops and Robbers game from graph theory where the respective agents move randomly with probability $(1-p)$ and $(1-q)$. 

The repository currently contains functions to simulate the game, generate transition matrices to model the game, and various scripts to help invert the $(I-Q)$ matrix to obtain the fundamental matrix.

Below is a simulation of the game using the Plots.jl and GraphPlots.jl framework. Instead of a cop and robber, we use a zombie and survivor. The game is being played on the hypercube graph where $p = q = 0.5$. The green "S" node represents the survivor, and the red "Z" nod
<br />
<p align="center">
    <img src="https://github.com/Garcese/cops_and_robbers/blob/main/simulation.gif" alt="animated" />
</p>

The $(I-Q)$ that we are looking to invert is a family of matrices of the following form (here, the maximum distance on the graph is either 10 or 11, and hence the matrix is 5 by 5).

```math
\begin{align*}
    \left(
    \begin{array}{@{}ccccc@{}} 
    	c_1+f_1+F_1 & -f_1 & -F_1 & 0 & 0           \\
    	-c_2 & C_2+c_2+f_2+F_2 & -f_2 & -F_2 & 0    \\
    	-C_3 & -c_3 & C_3+c_3+f_3+F_3 & -f_3 & -F_3 \\
    	0 & -C_4 & -c_4 & C_4+c_4+f_4 & -f_4        \\
        0 & 0 & -C_5 & -c_5 & C_5+c_5
    \end{array}
    \right)    
\end{align*}
```

Active work on the project is headed by Giancarlo Arcese (me) and professor Gabriel Sosa Castillo of Colgate Univesrity. Previous work by Pamela Harris, Alicia Pietro-Langarica, and Charles Smith.