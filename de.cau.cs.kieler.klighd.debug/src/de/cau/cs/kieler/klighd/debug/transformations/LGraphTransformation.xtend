package de.cau.cs.kieler.klighd.debug.transformations

import de.cau.cs.kieler.core.kgraph.KNode
import de.cau.cs.kieler.core.krendering.KRenderingFactory
import de.cau.cs.kieler.core.krendering.extensions.KColorExtensions
import de.cau.cs.kieler.core.krendering.extensions.KEdgeExtensions
import de.cau.cs.kieler.core.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.core.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.kiml.options.LayoutOptions
import de.cau.cs.kieler.kiml.util.KimlUtil
import de.cau.cs.kieler.klighd.TransformationContext
import org.eclipse.debug.core.model.IVariable

import static de.cau.cs.kieler.klighd.debug.transformations.LGraphTransformation.*
import de.cau.cs.kieler.core.util.Pair

class LGraphTransformation extends AbstractKNodeTransformation {
    
    extension KNodeExtensions kNodeExtensions = new KNodeExtensions()
    extension KEdgeExtensions kEdgeExtensions = new KEdgeExtensions()
    extension KRenderingExtensions kRenderingExtensions = new KRenderingExtensions()
    extension KColorExtensions kColorExtensions = new KColorExtensions()
    
    
    private static val KRenderingFactory renderingFactory = KRenderingFactory::eINSTANCE

    /**
     * {@inheritDoc}
     */
	override transform(IVariable variable,TransformationContext<IVariable,KNode> transformationContext) {
        use(transformationContext)

        return KimlUtil::createInitializedNode=> [
            it.addLayoutParam(LayoutOptions::ALGORITHM, "de.cau.cs.kieler.kiml.ogdf.planarization")
            it.addLayoutParam(LayoutOptions::SPACING, 75f)
      		it.createHeaderNode(variable)
      		it.createLayerlessNodes(variable.getVariableByName("layerlessNodes"))
      		it.createLayeredNodes(variable.getVariableByName("layers"))
      		it.createEdges(variable.getVariableByName("layerlessNodes"))
      		it.createEdges(variable.getVariableByName("layers"))
        ]

	}
	
	def createHeaderNode(KNode rootNode, IVariable variable) {
		rootNode.children += variable.createNode().putToLookUpWith(variable) => [
//    		it.setNodeSize(120,80)
    		it.data += renderingFactory.createKRectangle() => [
    			it.lineWidth = 4
    			it.backgroundColor = "lemon".color
    			it.ChildPlacement = renderingFactory.createKGridPlacement()
    			
                it.children += renderingFactory.createKText() => [
                    it.setText("name: " + variable.name)
                ]
                
                it.children += renderingFactory.createKText() => [
                    it.setText("hashCode: " + variable.getValueByName("hashCode"))
                ]
    			
    			it.children += renderingFactory.createKText() => [
    				it.setText("size (x,y): (" + variable.getValueByName("size.x") + ", " 
    				                           + variable.getValueByName("size.y") + ")" 
                    )
            	]
    			
    			it.children += renderingFactory.createKText() => [
                	it.setText("insets (t,r,b,l): (" + variable.getValueByName("insets.top") + ", "
                	                                 + variable.getValueByName("insets.right") + ", "
                	                                 + variable.getValueByName("insets.bottom") + ", "
                	                                 + variable.getValueByName("insets.left") + ")"
                	)
            	]
    			
    			it.children += renderingFactory.createKText() => [
                	it.setText("offset (x,y): (" + variable.getValueByName("offset.x") + ", "
                	                             + variable.getValueByName("offset.y") + ")"
                	)
            	]
            ]
		]
	}
	
	def createLayerlessNodes(KNode rootNode, IVariable variable) {
	    for (node : variable.linkedList) {
            nextTransformation(rootNode, node)
            
            val currentNode = rootNode.children.last
            //TODO: Layer is only specified in the outer graph, if there is one
            val currentData = currentNode.data.last

//            currentData += renderingFactory.createKText => [
//                it.setText("Layer: " + variable.getValueByName("owner.id")) 
//            ]
        }
	}
	
	def createLayeredNodes(KNode rootNode, IVariable variable) {
		for (node : variable.linkedList) {
            nextTransformation(rootNode, node)

            val currentNode = rootNode.children.last
            //TODO: Layer is only specified in the outer graph, if there is one
            val currentData = currentNode.data.last

//            currentData += renderingFactory.createKText => [
//                it.setText("Layer: " + variable.getValueByName("owner.id")) 
//            ]
        }
	}

    def createEdges(KNode rootNode, IVariable variable) {
        for (edge : variable.linkedList) {
            nextTransformation(rootNode, edge)
        }
    }
}